package main

import (
	"crypto/x509"
	"encoding/asn1"
	"encoding/pem"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
)

const (
	defaultKeysDir   = "./test-keys"
	attestationFile  = "Slot9CAttestation.pem"
	deviceCertFile   = "SlotF9Intermediate.pem"
	rootCertFilepath = "./piv-attestation-ca.pem"
)

var (
	YubiKeyFirmware       = asn1.ObjectIdentifier{1, 3, 6, 1, 4, 1, 41482, 3, 3}
	YubiKeySerial         = asn1.ObjectIdentifier{1, 3, 6, 1, 4, 1, 41482, 3, 7}
	YubiKeyPinTouchPolicy = asn1.ObjectIdentifier{1, 3, 6, 1, 4, 1, 41482, 3, 8}
	YubiKeyFormFactor     = asn1.ObjectIdentifier{1, 3, 6, 1, 4, 1, 41482, 3, 9}
	YubiKeyFIPS           = asn1.ObjectIdentifier{1, 3, 6, 1, 4, 1, 41482, 3, 10}
	YubiKeyCSPN           = asn1.ObjectIdentifier{1, 3, 6, 1, 4, 1, 41482, 3, 11}
)

func main() {
	pathToKeys := os.Getenv("ROOT_KEYS_PATH")
	if pathToKeys == "" {
		pathToKeys = defaultKeysDir
	}
	devices, err := os.ReadDir(pathToKeys)
	if err != nil {
		fmt.Println("Error reading directory:", err)
		return
	}
	if len(devices) == 0 {
		fmt.Println("No devices found in the directory:", pathToKeys)
		return
	}
	for _, device := range devices {
		if device.IsDir() {
			serial := device.Name()
			path := filepath.Join(pathToKeys, serial)
			err := verifyDeviceAttestation(serial, path)
			if err != nil {
				fmt.Println("Error verifying device attestation:", err)
				continue
			}
			fmt.Println("Device attestation verified for:", serial)
		}
	}
}

func verifyDeviceAttestation(serial, path string) error {
	// Verify attestation certificate
	att, err := decodeCertFromPath(filepath.Join(path, attestationFile))
	if err != nil {
		return fmt.Errorf("Failed to decode the attestation certificate: %s", err)
	}
	device, err := decodeCertFromPath(filepath.Join(path, deviceCertFile))
	if err != nil {
		return fmt.Errorf("Failed to decode the device certificate: %s", err)
	}
	root, err := decodeCertFromPath(rootCertFilepath)
	if err != nil {
		return fmt.Errorf("Failed to decode the root certificate: %s", err)
	}
	ok := verifyCert(att, device, root)
	if ok != nil {
		return fmt.Errorf("Failed to verify the attestation certificate: %s", ok)
	}

	// check device serial # in attestation certificate
	for _, ext := range att.Extensions {
		switch ex := ext.Id; {
		case ex.Equal(YubiKeySerial):
			var s int
			_, err := asn1.Unmarshal(ext.Value, &s)
			if err != nil {
				return fmt.Errorf("Failed to unmarshal the serial number: %s", err)
			}
			fmt.Println("YubiKey Serial Number:", s)
			intSerial, err := strconv.Atoi(serial)
			if err != nil {
				return fmt.Errorf("Failed to convert the serial number to an integer: %s", err)
			}
			if s != intSerial {
				return fmt.Errorf("serial number %d does not match %d in attestation certificate", intSerial, s)
			}
		}
	}

	// check FIPS compliance in device certificate
	var fips bool
	for _, ext := range device.Extensions {
		switch ex := ext.Id; {
		case ex.Equal(YubiKeyFIPS):
			fips = true
		}
	}
	if !fips {
		return fmt.Errorf("The device certificate is not FIPS compliant")
	}

	// print the digital signature public key from the attestation certificate
	pubKeyDER, err := x509.MarshalPKIXPublicKey(att.PublicKey)
	if err != nil {
		return fmt.Errorf("Failed to marshal the public key: %s", err)
	}
	pubKeyPEM := pem.EncodeToMemory(&pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: pubKeyDER,
	})
	fmt.Printf("Public Key:\n%s\n", string(pubKeyPEM))

	return nil
}

func decodeCertFromPath(path string) (*x509.Certificate, error) {
	// Read the PEM file
	certPEM, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("Failed to read the PEM file: %s", err)
	}

	// Decode the PEM certificate
	block, _ := pem.Decode(certPEM)
	if block == nil {
		return nil, fmt.Errorf("Failed to decode the PEM block containing the certificate")
	}

	// Parse the certificate
	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("Failed to parse the certificate: %s", err)
	}
	return cert, nil
}

func verifyCert(att, intermediate, root *x509.Certificate) error {
	// Create a pool of trusted certificates
	pool := x509.NewCertPool()
	pool.AddCert(intermediate)
	pool.AddCert(root)

	// Verify the certificate
	_, err := att.Verify(x509.VerifyOptions{
		Roots:         pool,
		Intermediates: pool,
	})
	if err != nil {
		return fmt.Errorf("failed to verify the certificate: %w", err)
	}
	return nil
}
