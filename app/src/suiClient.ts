import { SuiClient, getFullnodeUrl } from "@mysten/sui/client";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { fromB64 } from "@mysten/sui/utils";
import "dotenv/config";

const RPC_URL = process.env.SUI_RPC_URL || getFullnodeUrl("testnet");
const client = new SuiClient({ url: RPC_URL });

let cachedKeypair: Ed25519Keypair | null = null;

function deriveFromEnv(b64: string): Ed25519Keypair {
  const raw = fromB64(b64.trim());
  const secret = raw.length === 33 ? raw.slice(1) : raw; // strip scheme if present
  return Ed25519Keypair.fromSecretKey(secret);
}

export function getKeypair(): Ed25519Keypair {
  if (cachedKeypair) return cachedKeypair;
  const b64 = process.env.SUI_PRIVATE_KEY;
  if (!b64) {
    // Dev fallback: generate ephemeral keypair so app can still start.
    cachedKeypair = Ed25519Keypair.generate();
    console.warn("[suiClient] SUI_PRIVATE_KEY not set. Generated ephemeral keypair (address=" + cachedKeypair.getPublicKey().toSuiAddress() + "). Set one in .env to persist.");
    return cachedKeypair;
  }
  try {
    cachedKeypair = deriveFromEnv(b64);
  } catch (e) {
    console.warn("[suiClient] Failed to parse SUI_PRIVATE_KEY, generating ephemeral keypair. Error:", e);
    cachedKeypair = Ed25519Keypair.generate();
  }
  return cachedKeypair;
}

export function getClient(): SuiClient { return client; }

export function getActiveAddress(): string { return getKeypair().getPublicKey().toSuiAddress(); }
