// Deno 単体テスト（旅程Phase 4）: Google 呼び出し試行を漏れなく1回だけ費用計上
// する。fetch と計上を注入して、成功 / Google 4xx / 5xx / timeout / 通信例外 /
// 集計RPC失敗の各経路と、応答の transform を検証する。
//
// 実行: `deno test supabase/functions/routes-proxy/handler_test.ts`
// 注意: 本リポジトリの検証環境には Deno が無いため**未実行**（成功扱いにしない）。

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  callGoogle,
  type GoogleCallOptions,
  transformComputeRoutes,
} from "./handler.ts";

function baseOpts(overrides: Partial<GoogleCallOptions> = {}): GoogleCallOptions {
  return {
    environment: "development",
    url: "https://routes.googleapis.com/directions/v2:computeRoutes",
    apiKey: "test-key",
    fieldMask: "routes.duration,routes.distanceMeters",
    timeoutMs: 50,
    action: "compute_routes",
    travelMode: "walking",
    body: "{}",
    transform: (d) => d,
    ...overrides,
  };
}

function counter() {
  let count = 0;
  const skus: string[] = [];
  return {
    incrementUsage: (sku: string) => {
      count++;
      skus.push(sku);
      return Promise.resolve();
    },
    get calls() {
      return count;
    },
    get skus() {
      return skus;
    },
  };
}

Deno.test("成功: 計上1回・Essentials SKU・200", async () => {
  const c = counter();
  const res = await callGoogle(baseOpts(), {
    fetchFn: () => Promise.resolve(new Response("{}", { status: 200 })),
    incrementUsage: c.incrementUsage,
  });
  assertEquals(c.calls, 1);
  assertEquals(c.skus, ["compute_routes_essentials"]);
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
    fetchFn: () => Promise.reject(new DOMException("aborted", "AbortError")),
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
  assertEquals(fetched, false);
  assertEquals(res.status, 503);
});

Deno.test("transformComputeRoutes: 徒歩/車 相当（transitStepsなし）", () => {
  const out = transformComputeRoutes({
    routes: [{ duration: "930s", distanceMeters: 1200 }],
  }) as { durationMinutes: number; distanceMeters: number; fareText: unknown; transitSteps: unknown[] };
  assertEquals(out.durationMinutes, 16); // 930s → 15.5min → round → 16
  assertEquals(out.distanceMeters, 1200);
  assertEquals(out.fareText, null);
  assertEquals(out.transitSteps, []);
});

Deno.test("transformComputeRoutes: 公共交通（運賃・乗換ステップあり）", () => {
  const out = transformComputeRoutes({
    routes: [{
      duration: "1800s",
      distanceMeters: 5000,
      localizedValues: { transitFare: { text: "¥210" } },
      legs: [{
        steps: [{
          transitDetails: {
            transitLine: {
              name: "JR山手線",
              nameShort: "山手線",
              vehicle: { type: "HEAVY_RAIL" },
            },
            headsign: "渋谷方面",
            stopDetails: {
              departureStop: { name: "新宿駅" },
              arrivalStop: { name: "渋谷駅" },
            },
          },
        }],
      }],
    }],
  }) as {
    durationMinutes: number;
    fareText: string | null;
    transitSteps: Array<Record<string, unknown>>;
  };
  assertEquals(out.durationMinutes, 30);
  assertEquals(out.fareText, "¥210");
  assertEquals(out.transitSteps.length, 1);
  assertEquals(out.transitSteps[0].lineName, "JR山手線");
  assertEquals(out.transitSteps[0].departureStopName, "新宿駅");
  assertEquals(out.transitSteps[0].arrivalStopName, "渋谷駅");
});

Deno.test("transformComputeRoutes: routesが空でもクラッシュしない", () => {
  const out = transformComputeRoutes({ routes: [] }) as {
    durationMinutes: number;
    distanceMeters: number;
  };
  assertEquals(out.durationMinutes, 0);
  assertEquals(out.distanceMeters, 0);
});
