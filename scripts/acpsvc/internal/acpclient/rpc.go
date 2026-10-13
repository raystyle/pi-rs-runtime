// Package acpclient 提供 ACP v1 stdio 传输的换行分帧 JSON-RPC 编解码。
// 分帧与 TS 版 acpclient.ts 一致:一行一条,stdout 只有 ACP 消息。
package acpclient

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
)

// Request 是一条 JSON-RPC 请求或通知;无 ID 即通知。
type Request struct {
	ID     json.RawMessage `json:"id,omitempty"`
	Method string          `json:"method"`
	Params json.RawMessage `json:"params,omitempty"`
}

// Error 是 JSON-RPC 错误对象。
type Error struct {
	Code    int             `json:"code"`
	Message string          `json:"message"`
	Data    json.RawMessage `json:"data,omitempty"`
}

func (e *Error) Error() string { return fmt.Sprintf("rpc %d: %s", e.Code, e.Message) }

// Response 是一条应答;ID 与请求一致,Result 与 Error 二选一。
type Response struct {
	ID     json.RawMessage `json:"id"`
	Result json.RawMessage `json:"result,omitempty"`
	Error  *Error          `json:"error,omitempty"`
}

// Codec 按行编解码一对 stdio 流;写侧互斥由调用方保证(一会话一子进程)。
type Codec struct {
	r *bufio.Reader
	w io.Writer
}

// NewCodec 包一对读写流;读缓冲 1MiB,容纳长 prompt 的单行消息。
func NewCodec(rw io.ReadWriter) *Codec {
	return &Codec{r: bufio.NewReaderSize(rw, 1<<20), w: rw}
}

// Send 序列化一条消息并补换行;ACP stdio 帧尾是 \n。
func (c *Codec) Send(v any) error {
	b, err := json.Marshal(v)
	if err != nil {
		return err
	}
	if _, err := c.w.Write(append(b, '\n')); err != nil {
		return err
	}
	return nil
}

// Recv 读一条消息,去掉行尾 \r\n;流尾带半行时返回该半行,空流返回 io.EOF。
func (c *Codec) Recv() (json.RawMessage, error) {
	line, err := c.r.ReadBytes('\n')
	if err != nil && len(line) == 0 {
		return nil, err
	}
	return json.RawMessage(bytes.TrimRight(line, "\r\n")), nil
}
