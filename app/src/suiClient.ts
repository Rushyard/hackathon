import { SuiClient, getFullnodeUrl } from "@mysten/sui/client";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { fromB64 } from "@mysten/sui/utils";
import "dotenv/config";

const RPC_URL = process.env.SUI_RPC_URL || getFullnodeUrl("testnet");
const client = new SuiClient({ url: RPC_URL });

let cachedKeypair: Ed25519Keypair | null = null;

function fromEnv(b64: string): Ed25519Keypair {
  const raw = fromB64(b64.trim());
  const secret = raw.length === 33 ? raw.slice(1) : raw; // strip scheme byte if present
  return Ed25519Keypair.fromSecretKey(secret);
}

export function getKeypair(): Ed25519Keypair {
  if (cachedKeypair) return cachedKeypair;
  const envKey = process.env.SUI_PRIVATE_KEY;
  if (envKey) {
    try {
      cachedKeypair = fromEnv(envKey);
      return cachedKeypair;
    } catch (e) {
      console.warn(
        "[suiClient] Failed to parse SUI_PRIVATE_KEY, generating ephemeral keypair.",
        e,
      );
    }
  } else {
    console.warn(
      "[suiClient] SUI_PRIVATE_KEY not set, generating ephemeral keypair (dev only).",
    );
  }
  cachedKeypair = Ed25519Keypair.generate();
  console.warn(
    "[suiClient] Ephemeral address:",
    cachedKeypair.getPublicKey().toSuiAddress(),
  );
  return cachedKeypair;
}

export function getClient(): SuiClient {
  return client;
}
export function getActiveAddress(): string {
  return getKeypair().getPublicKey().toSuiAddress();
}
