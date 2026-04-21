import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "1m", target: 10 },
    { duration: "3m", target: 20 },
    { duration: "1m", target: 0 },
  ],
  thresholds: {
    http_req_failed: ["rate<0.05"],
    http_req_duration: ["p(95)<1000", "p(99)<2000"],
  },
};

const BASE_URL = __ENV.BASE_URL || "https://app.acme.local";

export default function () {
  const loginRes = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({ username: "bob", password: "User1234!" }),
    { headers: { "Content-Type": "application/json" } }
  );

  const cookies = loginRes.headers["Set-Cookie"];

  http.get(`${BASE_URL}/tickets/`, {
    headers: { Cookie: cookies },
  });

  http.get(`${BASE_URL}/health`);

  sleep(1);
}
