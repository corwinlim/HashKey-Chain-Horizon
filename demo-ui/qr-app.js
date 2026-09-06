(function (global) {
  "use strict";

  const forbiddenPrivacyKeys = new Set([
    "owner_government_id",
    "owner_address",
    "owner_contact",
    "medical_record",
    "clinical_record",
    "caios_memory",
    "caios_context",
    "recommendation_payload",
  ]);

  function canonicalJson(value) {
    if (value === null || typeof value !== "object") return JSON.stringify(value);
    if (Array.isArray(value)) return `[${value.map(canonicalJson).join(",")}]`;
    return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${canonicalJson(value[key])}`).join(",")}}`;
  }

  async function sha256Hex(value) {
    const bytes = new TextEncoder().encode(canonicalJson(value));
    const digest = await crypto.subtle.digest("SHA-256", bytes);
    return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
  }

  function toBase64Url(text) {
    const bytes = new TextEncoder().encode(text);
    let binary = "";
    for (const byte of bytes) binary += String.fromCharCode(byte);
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  }

  function fromBase64Url(token) {
    const base64 = token.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((token.length + 3) % 4);
    const binary = atob(base64);
    const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
    return new TextDecoder().decode(bytes);
  }

  function containsForbiddenKey(value) {
    if (value === null || typeof value !== "object") return false;
    if (Array.isArray(value)) return value.some(containsForbiddenKey);
    return Object.entries(value).some(([key, nested]) => forbiddenPrivacyKeys.has(key) || containsForbiddenKey(nested));
  }

  function payloadShapeValid(payload) {
    return Boolean(
      payload &&
      typeof payload === "object" &&
      typeof payload.version === "string" && payload.version.length > 0 &&
      typeof payload.petTrustId === "string" && payload.petTrustId.length > 0 &&
      Array.isArray(payload.credentialIds) && payload.credentialIds.length > 0 && payload.credentialIds.every((id) => typeof id === "string" && id.length > 0) &&
      typeof payload.issuerId === "string" && payload.issuerId.length > 0 &&
      typeof payload.nonce === "string" && payload.nonce.length > 0 &&
      typeof payload.issuedAt === "string" && payload.issuedAt.length > 0 &&
      (payload.scenario === "valid" || payload.scenario === "revoked")
    );
  }

  async function createEnvelope(payload) {
    return { payload, integrityHash: await sha256Hex(payload) };
  }

  function encode(envelope) {
    return toBase64Url(canonicalJson(envelope));
  }

  function decode(token) {
    try {
      const parsed = JSON.parse(fromBase64Url(token));
      if (!parsed || typeof parsed !== "object" || !("payload" in parsed) || !("integrityHash" in parsed)) throw new Error();
      return parsed;
    } catch {
      throw new Error("QR_MALFORMED");
    }
  }

  async function verifyEnvelope(envelope) {
    const failureCodes = [];
    if (!envelope || typeof envelope !== "object" || !payloadShapeValid(envelope.payload)) {
      return { valid: false, failureCodes: ["QR_MALFORMED"] };
    }
    if (envelope.payload.version !== "ctqr-v1") failureCodes.push("QR_VERSION_UNSUPPORTED");
    if (containsForbiddenKey(envelope.payload)) failureCodes.push("QR_PRIVACY_VIOLATION");
    if (typeof envelope.integrityHash !== "string" || await sha256Hex(envelope.payload) !== envelope.integrityHash) {
      failureCodes.push("QR_INTEGRITY_MISMATCH");
    }
    return { valid: failureCodes.length === 0, failureCodes: [...new Set(failureCodes)] };
  }

  global.CaniTrustQR = { canonicalJson, sha256Hex, createEnvelope, encode, decode, verifyEnvelope };
})(globalThis);
