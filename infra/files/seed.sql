INSERT INTO instruments (ticker, name, "timestamp") VALUES ('USD', 'US Dollar', '2026-01-07 08:47:07.986601+00') ON CONFLICT DO NOTHING;
INSERT INTO instruments (ticker, name, "timestamp") VALUES ('AAPL', 'Apple Inc.', '2026-01-07 08:47:07.986601+00') ON CONFLICT DO NOTHING;
INSERT INTO instruments (ticker, name, "timestamp") VALUES ('GOOGL', 'Alphabet Inc.', '2026-01-07 08:47:07.986601+00') ON CONFLICT DO NOTHING;
INSERT INTO instruments (ticker, name, "timestamp") VALUES ('MSFT', 'Microsoft Corporation', '2026-01-07 08:47:07.986601+00') ON CONFLICT DO NOTHING;
INSERT INTO instruments (ticker, name, "timestamp") VALUES ('TSLA', 'Tesla Inc.', '2026-01-07 08:47:07.986601+00') ON CONFLICT DO NOTHING;
INSERT INTO instruments (ticker, name, "timestamp") VALUES ('RUB', 'RUB', '2026-01-07 13:13:36.117734+00') ON CONFLICT DO NOTHING;

INSERT INTO users (id, name, api_key, role, "timestamp") VALUES ('64947659-27b9-4413-a87a-486801ee2033', 'Пользователь 1', 'key-65758a71-b6a5-4972-b01a-bb7155c9462b', 'USER', '2026-01-07 10:12:17.265682+00') ON CONFLICT DO NOTHING;
INSERT INTO users (id, name, api_key, role, "timestamp") VALUES ('d2adff8b-d839-4fda-ba4e-0f5437fa1ae2', 'Пользователь 2', 'key-7ff41fe8-226b-4215-9fec-e8af5bb0a910', 'USER', '2026-01-07 10:18:08.573327+00') ON CONFLICT DO NOTHING;
INSERT INTO users (id, name, api_key, role, "timestamp") VALUES ('11111111-1111-1111-1111-111111111111', 'Test User', 'test-api-key-123', 'ADMIN', '2026-01-07 08:47:07.987374+00') ON CONFLICT DO NOTHING;
INSERT INTO users (id, name, api_key, role, "timestamp") VALUES ('346639ac-b734-4902-b9db-ccdaeddbba11', 'admin', 'key-af910956-8eca-4d65-b350-a0fbbdbd178b', 'ADMIN', '2026-01-07 13:02:40.434515+00') ON CONFLICT DO NOTHING;

INSERT INTO balances (user_id, instrument_ticker, amount, locked) VALUES ('11111111-1111-1111-1111-111111111111', 'USD', 100000, 0) ON CONFLICT DO NOTHING;
INSERT INTO balances (user_id, instrument_ticker, amount, locked) VALUES ('11111111-1111-1111-1111-111111111111', 'AAPL', 100, 0) ON CONFLICT DO NOTHING;
INSERT INTO balances (user_id, instrument_ticker, amount, locked) VALUES ('64947659-27b9-4413-a87a-486801ee2033', 'RUB', 9800, 0) ON CONFLICT DO NOTHING;
INSERT INTO balances (user_id, instrument_ticker, amount, locked) VALUES ('64947659-27b9-4413-a87a-486801ee2033', 'USD', 1010, 0) ON CONFLICT DO NOTHING;
INSERT INTO balances (user_id, instrument_ticker, amount, locked) VALUES ('d2adff8b-d839-4fda-ba4e-0f5437fa1ae2', 'USD', 990, 8) ON CONFLICT DO NOTHING;
INSERT INTO balances (user_id, instrument_ticker, amount, locked) VALUES ('d2adff8b-d839-4fda-ba4e-0f5437fa1ae2', 'RUB', 200, 0) ON CONFLICT DO NOTHING;

INSERT INTO orders (id, user_id, direction, instrument_ticker, qty, price, type, status, "timestamp", filled) VALUES ('3ecdcf47-e251-4982-9c60-b6c59b10437d', 'd2adff8b-d839-4fda-ba4e-0f5437fa1ae2', 'SELL', 'USD', 5, 30, 'LIMIT', 'NEW', '2026-01-07 13:16:26.931453+00', 0) ON CONFLICT DO NOTHING;
INSERT INTO orders (id, user_id, direction, instrument_ticker, qty, price, type, status, "timestamp", filled) VALUES ('be7f8c5a-0431-4b5e-bef2-8fd416c596b4', 'd2adff8b-d839-4fda-ba4e-0f5437fa1ae2', 'SELL', 'USD', 3, 40, 'LIMIT', 'NEW', '2026-01-07 13:17:01.001368+00', 0) ON CONFLICT DO NOTHING;
INSERT INTO orders (id, user_id, direction, instrument_ticker, qty, price, type, status, "timestamp", filled) VALUES ('23390686-1f44-4160-a18f-ca74f4d7304d', 'd2adff8b-d839-4fda-ba4e-0f5437fa1ae2', 'SELL', 'USD', 10, 20, 'LIMIT', 'EXECUTED', '2026-01-07 13:16:11.946759+00', 10) ON CONFLICT DO NOTHING;
INSERT INTO orders (id, user_id, direction, instrument_ticker, qty, price, type, status, "timestamp", filled) VALUES ('6bfe0281-b4c6-4832-962c-e67866aac80c', '64947659-27b9-4413-a87a-486801ee2033', 'BUY', 'USD', 10, 40, 'LIMIT', 'EXECUTED', '2026-01-07 13:18:19.046422+00', 10) ON CONFLICT DO NOTHING;

INSERT INTO transactions (id, ticker, qty, price, "timestamp", buy_order_id, sell_order_id) VALUES ('8ef7df4d-0e9f-4410-bc4e-8b08ea1ebfe9', 'USD', 10, 20, '2026-01-07 13:18:19.072301+00', '23390686-1f44-4160-a18f-ca74f4d7304d', '6bfe0281-b4c6-4832-962c-e67866aac80c') ON CONFLICT DO NOTHING;
