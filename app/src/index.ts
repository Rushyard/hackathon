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
    case "create":
      console.log(await createCounter());
      break;
    case "increment":
      console.log(await increment(rest[0]));
      break;
    case "decrement":
      console.log(await decrement(rest[0]));
      break;
    case "set":
      console.log(await setValue(rest[0], Number(rest[1])));
      break;
    case "get":
      console.dir(await getCounter(rest[0]), { depth: 5 });
      break;
    case "events":
      console.log("Listening for CounterEvent...");
      await watchEvents((e) => console.log("Event:", e));
      break;
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
