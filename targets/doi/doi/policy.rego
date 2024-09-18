package attest

import rego.v1

# TODO: this is a placeholder, it should do more validation of the statements

keys := [
	{
		"id": "a0c296026645799b2a297913878e81b0aefff2a0c301e97232f717e14402f3e4",
		"key": "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEgH23D1i2+ZIOtVjmfB7iFvX8AhVN\n9CPJ4ie9axw+WRHozGnRy99U2dRge3zueBBg2MweF0zrToXGig2v3YOrdw==\n-----END PUBLIC KEY-----",
		"from": "2023-12-15T14:00:00Z",
		"to": null,
		"status": "active",
		"signing-format": "dssev1",
	},
	{
		"id": "b281835e00059de24fb06bd6db06eb0e4a33d7bd7210d7027c209f14b19e812a",
		"key": "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEgE4Jz6FrLc3lp/YRlbuwOjK4n6ac\njVkSDAmFhi3Ir2Jy+cKeEB7iRPcLvBy9qoMZ9E93m1NdWY6KtDo+Qi52Rg==\n-----END PUBLIC KEY-----",
		"from": "2023-12-15T14:00:00Z",
		"to": null,
		"status": "active",
		"signing-format": "dssev1",
	},
]

provs(pred) := p if {
	res := attest.fetch(pred)
	not res.error
	p := res.value
}

atts := union({
	provs("https://slsa.dev/provenance/v0.2"),
	provs("https://spdx.dev/Document"),
})

opts := {"keys": keys}

statements contains s if {
	some att in atts
	res := attest.verify(att, opts)
	not res.error
	s := res.value
}

subjects contains subject if {
	some statement in statements
	some subject in statement.subject
}

result := {
	"success": true,
	"violations": set(),
	"summary": {
		"subjects": subjects,
		"slsa_levels": ["SLSA_BUILD_LEVEL_3"],
		"verifier": "docker-official-images",
		"policy_uri": "https://docker.com/official/policy/v0.1",
	},
}
