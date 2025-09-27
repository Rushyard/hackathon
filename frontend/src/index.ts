// DEPRECATED: use /workspaces/hackathon/app/src/index.ts
import {
  createCounter,
  increment,
  decrement,
  setValue,
  getCounter,
  watchEvents,
} from "./counter.js";

async function main() {
  const [, , cmd, ...rest] = process.argv;

  switch (cmd) {
    case "create": {
      const res = await createCounter();
      console.log("Created:", res);
      break;
    }
    case "increment": {
      const id = rest[0];
      console.log(await increment(id));
      break;
    }
    case "decrement": {
      const id = rest[0];
      console.log(await decrement(id));
      break;
    }
    case "set": {
      const id = rest[0];
      const value = Number(rest[1]);
      console.log(await setValue(id, value));
      break;
    }
    case "get": {
      const id = rest[0];
      console.dir(await getCounter(id), { depth: 5 });
      break;
    }
    case "events": {
      console.log("Listening for CounterEvent...");
      await watchEvents((e) => console.log("Event:", e));
      break;
    }
    default:
      console.log(
        "Commands: create | increment <id> | decrement <id> | set <id> <value> | get <id> | events",
      );
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
