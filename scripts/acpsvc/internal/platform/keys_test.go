package platform

import "testing"

func mkKeys(t *testing.T) ([]Key, string) {
	t.Helper()
	tok, hash, err := NewToken()
	if err != nil {
		t.Fatal(err)
	}
	return []Key{
		{ID: "k1", Hash: hash, Label: "test", Role: RoleCaller},
		{ID: "legacy", Hash: HashToken("old-token"), Label: "imported", Role: RoleAdmin},
	}, tok
}

func TestCheckHitAndRole(t *testing.T) {
	keys, tok := mkKeys(t)
	k, err := Check(keys, tok)
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	if k.ID != "k1" || k.Role != RoleCaller {
		t.Fatalf("key = %+v", k)
	}
	if err := k.AdminOnly(); err != ErrForbidden {
		t.Fatalf("caller 调管理面应 ErrForbidden, got %v", err)
	}
}

func TestCheckLegacyAdmin(t *testing.T) {
	keys, _ := mkKeys(t)
	k, err := Check(keys, "old-token")
	if err != nil {
		t.Fatalf("err: %v", err)
	}
	if err := k.AdminOnly(); err != nil {
		t.Fatalf("admin 不应被拒: %v", err)
	}
}

func TestCheckMissAndDisabled(t *testing.T) {
	keys, tok := mkKeys(t)
	if _, err := Check(keys, "wrong"); err != ErrUnauthorized {
		t.Fatalf("miss err = %v", err)
	}
	keys[0].Disabled = true
	if _, err := Check(keys, tok); err != ErrUnauthorized {
		t.Fatalf("disabled err = %v", err)
	}
}

func TestNewTokenShape(t *testing.T) {
	tok, hash, err := NewToken()
	if err != nil {
		t.Fatal(err)
	}
	if len(tok) != 4+43 { // acp_ + 32 字节 base64url
		t.Fatalf("token len = %d", len(tok))
	}
	if HashToken(tok) != hash {
		t.Fatal("hash 不一致")
	}
}
