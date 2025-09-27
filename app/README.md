# Counter App (Replaces frontend folder)

Setup:

1. cp .env.example .env
2. Fill: SUI_RPC_URL=http://127.0.0.1:9000 SUI_PRIVATE_KEY_B64=BASE64_SECRET
   COUNTER_PACKAGE_ID=0xYOUR_PUBLISHED_PACKAGE
3. npm install
4. npm run build

Events: All modifying calls (increment, decrement, set) emit CounterEvent {
counter_id, new_value }.

Commands: node dist/index.js create node dist/index.js increment <counterId>
node dist/index.js decrement <counterId> node dist/index.js set <counterId> 42
node dist/index.js get <counterId> node dist/index.js events
