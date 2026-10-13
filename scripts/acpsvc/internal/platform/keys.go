// Package platform 持有平台面的密钥与鉴权模型:多密钥、双角色、常数时间比对。
// M0 是纯逻辑面;HTTP 中间件与限流桶在 M1 接上(S-0003 第 4 节)。
package platform

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"time"
)

// Role 是密钥角色;admin 全路由,caller 业务路由(shutdown 与 keys 族 403)。
type Role string

const (
	RoleAdmin  Role = "admin"
	RoleCaller Role = "caller"
)

// Key 是 keys.json 的一条;原文不落盘,只存 SHA-256 十六进制哈希。
type Key struct {
	ID       string    `json:"id"`
	Hash     string    `json:"hash"`
	Label    string    `json:"label"`
	Role     Role      `json:"role"`
	Disabled bool      `json:"disabled"`
	Created  time.Time `json:"created"`
}

var (
	// ErrUnauthorized 是 401 语义:未知、停用或缺席密钥。
	ErrUnauthorized = errors.New("platform: 无效密钥")
	// ErrForbidden 是 403 语义:角色无权调管理面路由。
	ErrForbidden = errors.New("platform: 角色无权调该路由")
)

// Check 对全部密钥做比对后取命中者;逐条常数时间比较,不按密钥个数提前返回。
func Check(keys []Key, token string) (Key, error) {
	sum := sha256.Sum256([]byte(token))
	want := hex.EncodeToString(sum[:])
	var hit Key
	found := false
	for _, k := range keys {
		if subtle.ConstantTimeCompare([]byte(k.Hash), []byte(want)) == 1 {
			hit, found = k, true
		}
	}
	if !found || hit.Disabled {
		return Key{}, ErrUnauthorized
	}
	return hit, nil
}

// AdminOnly 判本密钥是否有管理面权;caller 调 shutdown/keys 族时调用。
func (k Key) AdminOnly() error {
	if k.Role != RoleAdmin {
		return ErrForbidden
	}
	return nil
}

// NewToken 生成 acp_ 前缀 32 字节 base64url 令牌,返回令牌与其哈希行;原文只此一次可见。
func NewToken() (token, hash string, err error) {
	raw := make([]byte, 32)
	if _, err = rand.Read(raw); err != nil {
		return "", "", err
	}
	token = "acp_" + base64.RawURLEncoding.EncodeToString(raw)
	sum := sha256.Sum256([]byte(token))
	return token, hex.EncodeToString(sum[:]), nil
}

// HashToken 是令牌到哈希行的纯函数;导入 legacy token 时也走这里。
func HashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}
