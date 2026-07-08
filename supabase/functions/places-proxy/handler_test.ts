// Deno 単体テスト（旅程Phase 3 / Fix4）: Google 呼び出し試行を漏れなく1回だけ
// 費用計上する。fetch と計上を注入して、成功 / Google 4xx / 5xx / timeout /
// 通信例外 / 集計RPC失敗 の各経路を検証する。
//
// 実行: `deno test supabase/functions/places-proxy/handler_test.ts`
// 注意: 本リポジトリの検証環境には Deno が無いため**未実行**（成功扱いにしない）。

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { callGoogle, type GoogleCallOptions } from "./handler.ts";

function baseOpts(overrides: Partial<GoogleCallOptions> = {}): GoogleCallOptions {
  return {
    environment: "development",
    url: "https://places.googleapis.com/v1/places/x",
    method: "GET",
    apiKey: "test-key",
    fieldMask: "id,displayName,formattedAddress,attributions",
    timeoutMs: 50,
    sku: "place_details",
    action: "details",
    transform: (d) => d,
    ...overrides,
  };
}

function counter() {
  let count = 0;
  return {
    incrementUsage: () => {
      count++;
      return Promise.resolve();
    },
    get calls() {
      return count;
    },
  };
}

Deno.test("成功: 計上1回・200", async () => {
  const c = counter();
  const res = await callGoogle(baseOpts(), {
    fetchFn: () => Promise.resolve(new Response("{}", { status: 200 })),
    incrementUsage: c.incrementUsage,
  });
  assertEquals(c.calls, 1);
  assertEquals(res.status, 200);
});

Deno.test("Google 4xx: 計上1回・502", async () => {
  const c = counter();
  const res = await callGoogle(baseOpts(), {
    fetchFn: () => Promise.resolve(new Response("bad", { status: 400 })),
    incrementUsage: c.incrementUsage,
  });
  assertEquals(c.calls, 1);
  assertEquals(res.status, 502);
});

Deno.test("Google 5xx: 計上1回・502", async () => {
  const c = counter();
  const res = await callGoogle(baseOpts(), {
    fetchFn: () => Promise.resolve(new Response("err", { status: 503 })),
    incrementUsage: c.incrementUsage,
  });
  assertEquals(c.calls, 1);
  assertEquals(res.status, 502);
});

Deno.test("timeout(AbortError): 計上1回・504", async () => {
  const c = counter();
  const res = await callGoogle(baseOpts(), {
    fetchFn: () =>
      Promise.reject(new DOMException("aborted", "AbortError")),
    incrementUsage: c.incrementUsage,
  });
  assertEquals(c.calls, 1);
  assertEquals(res.status, 504);
});

Deno.test("通信例外: 計上1回・502", async () => {
  const c = counter();
  const res = await callGoogle(baseOpts(), {
    fetchFn: () => Promise.reject(new Error("network down")),
    incrementUsage: c.incrementUsage,
  });
  assertEquals(c.calls, 1);
  assertEquals(res.status, 502);
});

Deno.test("集計RPC失敗: Google を呼ばず unavailable(503)", async () => {
  let fetched = false;
  const res = await callGoogle(baseOpts(), {
    fetchFn: () => {
      fetched = true;
      return Promise.resolve(new Response("{}", { status: 200 }));
    },
    incrementUsage: () => Promise.reject(new Error("rpc failed")),
  });
  assertEquals(fetched, false); // Google へ送っていない
  assertEquals(res.status, 503);
});
