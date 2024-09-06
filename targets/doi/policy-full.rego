# doi/policy-full.rego verifies and validates the provenance and SBOM attestations attached to the image
package attest

import rego.v1

split_digest := split(input.digest, ":")

digest_type := split_digest[0]

digest := split_digest[1]

keys := [{
	"id": "11681ba744a6b4efa85132e884e56a6e6aa6dcde123fbc4e79fd3fb2e1cf186b", # production
	"key": "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEFwhMAaawBNowyj/w35RtAqeWllCe\nKt83A6nxMnQfVYFEHTWPj9EvgV03ogMy63i/9Hfi2lWihO+4g2vzSS02Gg==\n-----END PUBLIC KEY-----",
	"from": "2023-05-28T19:25:00Z",
	"to": null,
	"status": "active",
	"distrust": false,
	"signing-format": "dssev1",
}]

verify_opts := {"keys": keys}

verify_attestation(att) := attest.verify(att, verify_opts)

provenance_attestations contains att if {
	result := attest.fetch("https://slsa.dev/provenance/v0.2")
	not result.error
	some att in result.value
}

provenance_signed_statements contains statement if {
	some att in provenance_attestations
	result := verify_attestation(att)
	not result.error
	statement := result.value
}

provenance_subjects contains subject if {
	some statement in provenance_signed_statements
	some subject in statement.subject
}

# we need to key this by statement_id rather than statement because we can't
# use an object as a key due to a bug(?) in OPA: https://github.com/open-policy-agent/opa/issues/6736
provenance_statement_violations[statement_id] contains v if {
	some att in provenance_attestations
	result := verify_attestation(att)
	err := result.error
	statement := unsafe_statement_from_attestation(att)
	statement_id := id(statement)
	v := {
		"type": "unsigned_statement",
		"description": sprintf("Statement is not correctly signed: %v", [err]),
		"attestation": statement,
		"details": {"error": err},
	}
}

provenance_statement_violations[statement_id] contains v if {
	some statement in provenance_signed_statements
	statement_id := id(statement)
	v := field_value_does_not_equal(statement, "buildType", "https://mobyproject.org/buildkit@v1", "wrong_build_type")
}

provenance_statement_violations[statement_id] contains v if {
	some statement in provenance_signed_statements
	statement_id := id(statement)
	v := field_value_does_not_equal(statement, "metadata.completeness.materials", true, "incomplete_materials")
}

bad_provenance_statements contains statement if {
	some statement in provenance_signed_statements
	statement_id := id(statement)
	provenance_statement_violations[statement_id]
}

good_provenance_statements := provenance_signed_statements - bad_provenance_statements

sbom_attestations contains att if {
	result := attest.fetch("https://spdx.dev/Document")
	not result.error
	some att in result.value
}

sbom_signed_statements contains statement if {
	some att in sbom_attestations
	result := verify_attestation(att)
	not result.error
	statement := result.value
}

sbom_subjects contains subject if {
	some statement in sbom_signed_statements
	some subject in statement.subject
}

# we need to key this by statement_id rather than statement because we can't
# use an object as a key due to a bug(?) in OPA: https://github.com/open-policy-agent/opa/issues/6736
sbom_statement_violations[statement_id] contains v if {
	some att in sbom_attestations
	result := verify_attestation(att)
	err := result.error
	statement := unsafe_statement_from_attestation(att)
	statement_id := id(statement)
	v := {
		"type": "unsigned_statement",
		"description": sprintf("Statement is not correctly signed: %v", [err]),
		"attestation": statement,
		"details": {"error": err},
	}
}

sbom_statement_violations[statement_id] contains v if {
	some statement in sbom_signed_statements
	statement_id := id(statement)
	v := field_value_does_not_equal(statement, "SPDXID", "SPDXRef-DOCUMENT", "wrong_spdx_id")
}

bad_sbom_statements contains statement if {
	some statement in sbom_signed_statements
	statement_id := id(statement)
	sbom_statement_violations[statement_id]
}

good_sbom_statements := sbom_signed_statements - bad_sbom_statements

global_violations contains v if {
	count(sbom_attestations) == 0
	v := {
		"type": "missing_attestation",
		"description": "No https://slsa.dev/provenance/v0.2 attestation found",
		"attestation": null,
		"details": {},
	}
}

global_violations contains v if {
	count(provenance_attestations) == 0
	v := {
		"type": "missing_attestation",
		"description": "No https://spdx.dev/Document attestation found",
		"attestation": null,
		"details": {},
	}
}

all_violations contains v if {
	some v in global_violations
}

all_violations contains v if {
	some violations in sbom_statement_violations
	some v in violations
}

all_violations contains v if {
	some violations in provenance_statement_violations
	some v in violations
}

subjects := union({sbom_subjects, provenance_subjects})

result := {
	"success": allow,
	"violations": all_violations,
	"summary": {
		"subjects": subjects,
		"policy_uri": "https://docker.com/official/policy/v0.1",
	},
}

default allow := false

allow if {
	count(good_sbom_statements) > 0
	count(good_provenance_statements) > 0
}

id(statement) := crypto.sha256(json.marshal(statement))

field_value_does_not_equal(statement, field, expected, type) := v if {
	path := split(field, ".")
	actual := object.get(statement.predicate, path, null)
	expected != actual
	v := is_not_violation(statement, field, expected, actual, type)
}

array_field_does_not_contain(statement, field, expected, type) := v if {
	path := split(field, ".")
	actual := object.get(statement.predicate, path, null)
	not expected in actual
	v := not_contains_violation(statement, field, expected, actual, type)
}

is_not_violation(statement, field, expected, actual, type) := {
	"type": type,
	"description": sprintf("%v is not %v", [field, expected]),
	"attestation": statement,
	"details": {
		"field": field,
		"actual": actual,
		"expected": expected,
	},
}

not_contains_violation(statement, field, expected, actual, type) := {
	"type": type,
	"description": sprintf("%v does not contain %v", [field, expected]),
	"attestation": statement,
	"details": {
		"field": field,
		"actual": actual,
		"expected": expected,
	},
}

# This is unsafe because we're not checking the signature on the attestation,
# do not call this unless you've already verified the attestation or you need the
# statement for some other reason
unsafe_statement_from_attestation(att) := statement if {
	payload := att.payload
	statement := json.unmarshal(base64.decode(payload))
}
