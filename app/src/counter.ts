import { getClient, getKeypair } from "./suiClient.js";
import type { SuiObjectData } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions";

const PACKAGE_ID = process.env.COUNTER_PACKAGE_ID || "0xYOUR_PACKAGE_ID";
const MODULE = "counter";
const COUNTER_STRUCT = `${PACKAGE_ID}::${MODULE}::Counter`;
const EVENT_TYPE = `${PACKAGE_ID}::${MODULE}::CounterEvent`;

const client = getClient();
const keypair = getKeypair();

export async function createCounter() {
  const tx = new Transaction();
  tx.moveCall({ target: `${PACKAGE_ID}::${MODULE}::create` });
  const res = await client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair,
    options: { showObjectChanges: true, showEffects: true },
  });
  const created = res.objectChanges?.find(
    (c: any) => c.type === "created" && c.objectType === COUNTER_STRUCT,
  );
  const counterId =
    created && (created as any).objectId ? (created as any).objectId : null;
  return { digest: res.digest, counterId };
}

export async function increment(counterId: string) {
  const tx = new Transaction();
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::increment`,
    arguments: [tx.object(counterId)],
  });
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair,
    options: { showEffects: true },
  });
}

export async function decrement(counterId: string) {
  const tx = new Transaction();
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::decrement`,
    arguments: [tx.object(counterId)],
  });
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair,
    options: { showEffects: true },
  });
}

export async function setValue(counterId: string, value: number) {
  const tx = new Transaction();
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::set_value`,
    arguments: [tx.object(counterId), tx.pure.u64(BigInt(value))],
  });
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair,
    options: { showEffects: true },
  });
}

export async function getCounter(
  counterId: string,
): Promise<SuiObjectData | null> {
  const obj = await client.getObject({
    id: counterId,
    options: { showContent: true },
  });
  return obj.data || null;
}

export async function watchEvents(onEvent: (e: any) => void) {
  return client.subscribeEvent({
    filter: { MoveEventType: EVENT_TYPE },
    onMessage: (raw: unknown) => {
      if (typeof raw === "object" && raw !== null && "parsedJson" in raw) {
        const r: any = raw;
        const fields = (r.parsedJson ?? {}) as {
          counter_id?: any;
          new_value?: any;
        };
        onEvent({
          id: fields.counter_id,
          value: fields.new_value,
        });
      } else {
        onEvent(raw);
      }
    },
  });
}
