<!-- DEPRECATED: use /workspaces/hackathon/app/README.md -->

# Counter Frontend

1. cp .env.example .env and set: SUI_RPC_URL=http://127.0.0.1:9000
   SUI_PRIVATE_KEY_B64=BASE64_SECRET COUNTER_PACKAGE_ID=0xYOUR_PACKAGE_ID
2. npm install
3. npm run build

Examples: node dist/index.js create node dist/index.js increment <counterId>
node dist/index.js decrement <counterId> node dist/index.js set <counterId> 42
node dist/index.js get <counterId> node dist/index.js events
