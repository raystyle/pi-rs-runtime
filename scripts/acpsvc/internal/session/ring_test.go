package session

import "testing"

func TestRingMonotonicID(t *testing.T) {
	r := NewRing()
	for i := 0; i < 3; i++ {
		if got := r.Append(i).ID; got != uint64(i+1) {
			t.Fatalf("id = %d, want %d", got, i+1)
		}
	}
}

func TestReplayFromZero(t *testing.T) {
	r := NewRing()
	r.Append("a")
	r.Append("b")
	evs, gap := r.Replay(0)
	if gap || len(evs) != 2 {
		t.Fatalf("evs=%d gap=%v, want 2/false", len(evs), gap)
	}
}

func TestReplayAfterID(t *testing.T) {
	r := NewRing()
	r.Append("a")
	e := r.Append("b")
	r.Append("c")
	evs, gap := r.Replay(e.ID)
	if gap || len(evs) != 1 || evs[0].Data.(string) != "c" {
		t.Fatalf("evs=%d gap=%v", len(evs), gap)
	}
}

func TestReplayGap(t *testing.T) {
	r := NewRing()
	for i := 0; i < RingMax+10; i++ {
		r.Append(i)
	}
	evs, gap := r.Replay(5)
	if !gap {
		t.Fatal("滑出环的 after 应报 gap")
	}
	if len(evs) != RingMax {
		t.Fatalf("evs = %d, want %d", len(evs), RingMax)
	}
	if evs[0].ID != 11 { // 最旧保留是第 11 条
		t.Fatalf("oldest = %d, want 11", evs[0].ID)
	}
}

func TestReplayNoGapAtContiguousEdge(t *testing.T) {
	r := NewRing()
	for i := 0; i < RingMax+1; i++ {
		r.Append(i)
	}
	oldest := r.events[0].ID
	evs, gap := r.Replay(oldest - 1)
	if gap || len(evs) != RingMax {
		t.Fatalf("contiguous 边界不应 gap:evs=%d gap=%v", len(evs), gap)
	}
}
