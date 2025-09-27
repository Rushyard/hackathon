// DEPRECATED: use /workspaces/hackathon/app/src/counter.ts
import { getClient, getKeypair } from "./suiClient.js";
import type { SuiObjectData } from "@mysten/sui.js/client";

const PACKAGE_ID = process.env.COUNTER_PACKAGE_ID || "0xYOUR_PACKAGE_ID";
const MODULE = "counter";
const COUNTER_STRUCT = `${PACKAGE_ID}::${MODULE}::Counter`;
const CREATE_FN = "create";
const INCREMENT_FN = "increment";
const DECREMENT_FN = "decrement";
const SET_VALUE_FN = "set_value";
const EVENT_TYPE = `${PACKAGE_ID}::${MODULE}::CounterEvent`;

const client = getClient();
const keypair = getKeypair();

export async function createCounter() {
  const tx = {
    kind: "moveCall" as const,
    data: {
      packageObjectId: PACKAGE_ID,
      module: MODULE,
      function: CREATE_FN,
      arguments: [],
      typeArguments: [],
    },
  };
  // Using transaction blocks (recommended) but keep minimal: use devInspect or TransactionBlock in prod.
  const { effects, objectChanges } = await client.signAndExecuteTransaction({
    signer: keypair,
    transaction: {
      kind: "ProgrammableTransaction",
      transactions: [tx],
      inputs: [],
      type: "v2",
    },
    options: { showEffects: true, showObjectChanges: true },
  });
  const created = objectChanges?.find(
    (c) => c.type === "created" && c.objectType === COUNTER_STRUCT,
  );
  return {
    digest: effects?.transactionDigest,
    counterId: created ? created.objectId : null,
  };
}

export async function callSingleTarget(
  functionName: string,
  counterId: string,
  extraArgs: any[] = [],
) {
  const txb = {
    kind: "ProgrammableTransaction" as const,
    inputs: [],
    transactions: [
      {
        kind: "moveCall" as const,
        data: {
          packageObjectId: PACKAGE_ID,
          module: MODULE,
          function: functionName,
          arguments: [
            { kind: "Input", index: 0 }, // &mut Counter
            ...extraArgs.map((_, i) => ({ kind: "Input", index: i + 1 })),
          ],
          typeArguments: [],
        },
      },
    ],
    // Minimal input representations
  };
  // NOTE: The above is a simplified placeholder. Prefer TransactionBlock API in real code.
  throw new Error(
    "Replace placeholder low-level transaction assembly with TransactionBlock from @mysten/sui.js",
  );
}

export async function increment(counterId: string) {
  // Placeholder high-level example using TransactionBlock:
  const { TransactionBlock } = await import("@mysten/sui.js/transactions");
  const tx = new TransactionBlock();
  const obj = tx.object(counterId);
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::${INCREMENT_FN}`,
    arguments: [obj],
  });
  const res = await client.signAndExecuteTransactionBlock({
    transactionBlock: tx,
    signer: keypair,
    options: { showEffects: true },
  });
  return res;
}

export async function decrement(counterId: string) {
  const { TransactionBlock } = await import("@mysten/sui.js/transactions");
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::${DECREMENT_FN}`,
    arguments: [tx.object(counterId)],
  });
  return client.signAndExecuteTransactionBlock({
    transactionBlock: tx,
    signer: keypair,
    options: { showEffects: true },
  });
}

export async function setValue(counterId: string, value: number) {
  const { TransactionBlock } = await import("@mysten/sui.js/transactions");
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::${MODULE}::${SET_VALUE_FN}`,
    arguments: [tx.object(counterId), tx.pure.u64(BigInt(value))],
  });
  return client.signAndExecuteTransactionBlock({
    transactionBlock: tx,
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
    onMessage: onEvent,
  });
}
