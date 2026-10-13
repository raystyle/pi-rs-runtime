package acpclient

import (
	"bytes"
	"encoding/json"
	"io"
	"testing"
)

func TestCodecRoundtrip(t *testing.T) {
	var buf bytes.Buffer
	c := NewCodec(&buf)
	req := Request{ID: json.RawMessage(`1`), Method: "initialize", Params: json.RawMessage(`{"protocolVersion":1}`)}
	if err := c.Send(req); err != nil {
		t.Fatalf("Send: %v", err)
	}
	got, err := c.Recv()
	if err != nil {
		t.Fatalf("Recv: %v", err)
	}
	var back Request
	if err := json.Unmarshal(got, &back); err != nil {
		t.Fatalf("Unmarshal %s: %v", got, err)
	}
	if back.Method != "initialize" {
		t.Fatalf("method = %q", back.Method)
	}
}

func TestCodecErrorFrame(t *testing.T) {
	var buf bytes.Buffer
	buf.WriteString(`{"id":7,"error":{"code":-32601,"message":"method not found"}}` + "\n")
	c := NewCodec(&buf)
	raw, err := c.Recv()
	if err != nil {
		t.Fatalf("Recv: %v", err)
	}
	var resp Response
	if err := json.Unmarshal(raw, &resp); err != nil {
		t.Fatalf("Unmarshal: %v", err)
	}
	if resp.Error == nil || resp.Error.Code != -32601 {
		t.Fatalf("error frame = %+v", resp.Error)
	}
}

func TestRecvEOF(t *testing.T) {
	c := NewCodec(new(bytes.Buffer))
	if _, err := c.Recv(); err != io.EOF {
		t.Fatalf("err = %v, want io.EOF", err)
	}
}
