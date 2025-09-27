// DEPRECATED: use /workspaces/hackathon/app/src/suiClient.ts
import {
  SuiClient,
  getFullnodeUrl,
  Ed25519Keypair,
  fromB64,
} from "@mysten/sui.js";
import "dotenv/config";

const RPC_URL = process.env.SUI_RPC_URL || getFullnodeUrl("localnet");
// Base64-encoded private key bytes (NOT the 0x hex). For local testing only.
const PRIVATE_KEY_B64 = process.env.SUI_PRIVATE_KEY_B64 || "";

export function getClient() {
  return new SuiClient({ url: RPC_URL });
}

export function getKeypair(): Ed25519Keypair {
  if (!PRIVATE_KEY_B64) throw new Error("Set SUI_PRIVATE_KEY_B64 in .env");
  const raw = fromB64(PRIVATE_KEY_B64);
  // Ed25519 export format may include scheme flag; accept 32 or 33 bytes.
  const secret = raw.length === 33 ? raw.slice(1) : raw;
  return Ed25519Keypair.fromSecretKey(secret);
}
