package main

import (
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
)

const pathToKeys = "./test-keys"

func TestMain(t *testing.T) {
	testCases := []struct {
		name   string
		serial string
		fail   bool
	}{
		{"valid FIPS YubiKey", "25516106", false},
		{"not a FIPS YubiKey", "26551025", true},
		{"invalid serial number", "12345678", true},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			serial := tc.serial
			path := filepath.Join(pathToKeys, serial)
			err := verifyDeviceAttestation(serial, path)
			if tc.fail {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}
