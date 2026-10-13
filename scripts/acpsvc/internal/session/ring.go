// Package session 持有会话表与每会话事件环。
// 环在写入时分配单调整数 id;SSE 重连带 Last-Event-ID 或 after 时按 id 断点重放,
// 请求的 id 已滑出环时从最旧重放并报 gap(S-0003 第 4 节)。
package session

// RingMax 是单会话事件环上限,与 TS 版一致。
const RingMax = 2000

// Event 是环上一条事件;Data 是 session/update 等载荷原样。
type Event struct {
	ID   uint64
	Data any
}

// Ring 是无锁事件环;M0 单测单线程使用,M1 接入 HTTP 后由会话锁保护。
type Ring struct {
	events []Event
	next   uint64
}

// NewRing 建空环;id 从 1 起。
func NewRing() *Ring { return &Ring{} }

// Append 记一条事件并返回带 id 的副本;环满丢最旧。
func (r *Ring) Append(data any) Event {
	r.next++
	e := Event{ID: r.next, Data: data}
	r.events = append(r.events, e)
	if len(r.events) > RingMax {
		r.events = r.events[len(r.events)-RingMax:]
	}
	return e
}

// Replay 返回 id 大于 after 的事件。after 为零即全量重放;
// after 指向已滑出环的旧位置时,从最旧一条重放并报 gap=true。
func (r *Ring) Replay(after uint64) (evs []Event, gap bool) {
	if len(r.events) == 0 {
		return nil, false
	}
	oldest := r.events[0].ID
	gap = after != 0 && after+1 < oldest
	for _, e := range r.events {
		if e.ID > after {
			evs = append(evs, e)
		}
	}
	return evs, gap
}
