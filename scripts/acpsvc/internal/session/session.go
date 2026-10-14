// Package session 除事件环外,持有会话表与权限应答簿。
// 一会话一个适配器子进程;广播先入环(带 id)再推订阅者(SSE 消费)。
package session

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/raystyle/pi-rs-runtime/scripts/acpsvc/internal/acpclient"
)

// PermissionWait 是权限卡的平台应答时限;超时自动 cancelled(禁 allow_always 空窗)。
// var 而非 const:测试缩短时限用。
var PermissionWait = 120 * time.Second

// Envelope 是平台事件包(SSE 的 data 载荷);与 TS 版同形。
type Envelope struct {
	Kind      string          `json:"kind"`
	RequestID string          `json:"requestId,omitempty"`
	Update    json.RawMessage `json:"update,omitempty"`
	Request   json.RawMessage `json:"request,omitempty"`
}

// Slot 是一张权限卡的应答槽。
type Slot struct {
	ID      string
	done    chan struct{}
	once    sync.Once
	outcome chan json.RawMessage // 权限选项结果
}

func (s *Slot) finish() { s.once.Do(func() { close(s.done) }) }

// Reply 提交应答;已应答或超时返回 false。
func (s *Slot) Reply(optionID string) bool {
	out, _ := json.Marshal(map[string]any{"outcome": map[string]any{"outcome": "selected", "optionId": optionID}})
	select {
	case <-s.done:
		return false
	default:
	}
	select {
	case s.outcome <- out:
		s.finish()
		return true
	case <-s.done:
		return false
	}
}

// Wait 等平台应答或超时;超时返回 cancelled 并封槽(迟到的应答回 false)。
func (s *Slot) Wait(ctx context.Context) json.RawMessage {
	timer := time.NewTimer(PermissionWait)
	defer timer.Stop()
	select {
	case out := <-s.outcome:
		return out
	case <-timer.C:
	case <-ctx.Done():
	}
	s.finish()
	cancelled, _ := json.Marshal(map[string]any{"outcome": map[string]any{"outcome": "cancelled"}})
	return cancelled
}

// Session 是一个活动会话。
type Session struct {
	ID    string
	Agent string
	Cwd   string
	KeyID string
	Ag    *acpclient.Agent

	ringMu sync.Mutex
	ring   *Ring

	subsMu sync.Mutex
	subs   map[chan Event]struct{}

	promptsMu      sync.Mutex
	promptInFlight bool

	actMu   sync.Mutex
	lastAct time.Time

	permMu  sync.Mutex
	perms   map[string]*Slot
	permSeq int

	closed chan struct{}
}

// NewSession 建会话;广播环与会话同生命周期。
func NewSession(id, agent, cwd, keyID string, ag *acpclient.Agent) *Session {
	return &Session{
		ID: id, Agent: agent, Cwd: cwd, KeyID: keyID, Ag: ag, lastAct: time.Now(),
		ring:   NewRing(),
		subs:   make(map[chan Event]struct{}),
		perms:  make(map[string]*Slot),
		closed: make(chan struct{}),
	}
}

// touch 记最近活动(空闲逐出判据)。
func (s *Session) touch() {
	s.actMu.Lock()
	s.lastAct = time.Now()
	s.actMu.Unlock()
}

// Idle 判断会话是否空闲超时。
func (s *Session) Idle(ttl time.Duration) bool {
	s.actMu.Lock()
	defer s.actMu.Unlock()
	return time.Since(s.lastAct) > ttl
}

// Broadcast 入环并推订阅者;返回分配的事件 id。
func (s *Session) Broadcast(env Envelope) uint64 {
	s.touch()
	s.ringMu.Lock()
	ev := s.ring.Append(env)
	s.ringMu.Unlock()
	s.subsMu.Lock()
	for ch := range s.subs {
		select {
		case ch <- Event{ID: ev.ID, Data: env}:
		default: // 订阅者落后即丢;SSE 断线重连靠环回放
		}
	}
	s.subsMu.Unlock()
	return ev.ID
}

// Subscribe 订阅实时事件;返回通道与退订函数。
func (s *Session) Subscribe() (<-chan Event, func()) {
	ch := make(chan Event, 64)
	s.subsMu.Lock()
	s.subs[ch] = struct{}{}
	s.subsMu.Unlock()
	return ch, func() {
		s.subsMu.Lock()
		delete(s.subs, ch)
		s.subsMu.Unlock()
	}
}

// Replay 按 after 重放(断点语义同 Ring)。
func (s *Session) Replay(after uint64) ([]Event, bool) {
	s.ringMu.Lock()
	defer s.ringMu.Unlock()
	return s.ring.Replay(after)
}

// NewSlot 登记一张权限卡;返回槽与请求 id。
func (s *Session) NewSlot() (*Slot, string) {
	s.permMu.Lock()
	defer s.permMu.Unlock()
	s.permSeq++
	id := fmt.Sprintf("perm-%d-%06d", time.Now().UnixMilli(), s.permSeq)
	slot := &Slot{ID: id, done: make(chan struct{}), outcome: make(chan json.RawMessage, 1)}
	s.perms[id] = slot
	return slot, id
}

// TakeSlot 取走应答槽(应答或清理用);不存在返回 nil。
func (s *Session) TakeSlot(id string) *Slot {
	s.permMu.Lock()
	defer s.permMu.Unlock()
	slot, ok := s.perms[id]
	if ok {
		delete(s.perms, id)
	}
	return slot
}

// TryPrompt 抢占本会话唯一 prompt 位;占用中返回 false(409 语义)。
func (s *Session) TryPrompt() (release func(), ok bool) {
	s.promptsMu.Lock()
	defer s.promptsMu.Unlock()
	if s.promptInFlight {
		return nil, false
	}
	s.promptInFlight = true
	s.touch()
	var once sync.Once
	return func() {
		once.Do(func() {
			s.promptsMu.Lock()
			s.promptInFlight = false
			s.promptsMu.Unlock()
		})
	}, true
}

// PromptInFlight 报本会话是否有在途回合(换模等面判 409 用)。
func (s *Session) PromptInFlight() bool {
	s.promptsMu.Lock()
	defer s.promptsMu.Unlock()
	return s.promptInFlight
}

// Close 结束会话:关适配器 stdin 等自退,幂等。
func (s *Session) Close() {
	select {
	case <-s.closed:
		return
	default:
		close(s.closed)
	}
	if s.Ag != nil {
		go s.Ag.Close()
	}
}

func (s *Session) Done() <-chan struct{} { return s.closed }

// Table 是全局会话表;计数同时供全局与每密钥上限判定。
type Table struct {
	mu        sync.Mutex
	byID      map[string]*Session
	globalMax int
	perKeyMax int
}

// NewTable 建表;上限零值表示不限。
func NewTable(globalMax, perKeyMax int) *Table {
	return &Table{byID: make(map[string]*Session), globalMax: globalMax, perKeyMax: perKeyMax}
}

// ErrLimited 是 429 语义:会话上限打满。
var ErrLimited = fmt.Errorf("session: 会话上限打满")

// Add 判限后入表。
func (t *Table) Add(s *Session) error {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.globalMax > 0 && len(t.byID) >= t.globalMax {
		return ErrLimited
	}
	if t.perKeyMax > 0 {
		n := 0
		for _, e := range t.byID {
			if e.KeyID == s.KeyID {
				n++
			}
		}
		if n >= t.perKeyMax {
			return ErrLimited
		}
	}
	t.byID[s.ID] = s
	return nil
}

// Get 取会话。
func (t *Table) Get(id string) *Session {
	t.mu.Lock()
	defer t.mu.Unlock()
	return t.byID[id]
}

// Remove 出表。
func (t *Table) Remove(id string) {
	t.mu.Lock()
	defer t.mu.Unlock()
	delete(t.byID, id)
}

// SweepIdle 逐出空闲超时会话(关适配器 stdin 自退,订阅面经 Done 通道收尾);返回逐出数。
func (t *Table) SweepIdle(ttl time.Duration) int {
	t.mu.Lock()
	var out []*Session
	for id, s := range t.byID {
		if s.Idle(ttl) {
			out = append(out, s)
			delete(t.byID, id)
		}
	}
	t.mu.Unlock()
	for _, s := range out {
		s.Close()
	}
	return len(out)
}

// Len 返回当前会话数。
func (t *Table) Len() int {
	t.mu.Lock()
	defer t.mu.Unlock()
	return len(t.byID)
}
