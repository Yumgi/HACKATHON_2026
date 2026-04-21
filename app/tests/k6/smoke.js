import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 1,
  duration: "30s",
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<500"],
  },
};

const BASE_URL = __ENV.BASE_URL || "https://app.acme.local";

export default function () {
  // Healthcheck
  const health = http.get(`${BASE_URL}/health`, {
    tags: { name: "healthcheck" },
  });
  check(health, {
    "health status 200": (r) => r.status === 200,
    "health body ok": (r) => JSON.parse(r.body).status === "ok",
  });

  // Login
  const loginRes = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({ username: "bob", password: "User1234!" }),
    { headers: { "Content-Type": "application/json" }, tags: { name: "login" } }
  );
  check(loginRes, {
    "login 200": (r) => r.status === 200,
    "login role": (r) => JSON.parse(r.body).role !== undefined,
  });

  // Liste des tickets
  const jar = http.cookieJar();
  const tickets = http.get(`${BASE_URL}/tickets/`, {
    headers: { Cookie: loginRes.headers["Set-Cookie"] },
    tags: { name: "list_tickets" },
  });
  check(tickets, { "tickets 200": (r) => r.status === 200 });

  sleep(1);
}
