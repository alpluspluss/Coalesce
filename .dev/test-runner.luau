--[[
	TestRunner
	-> Environment-dependent testing framework with benchmarking.
	
	-> Compatible with
		- Native Luau
		- Roblox
]]
--!native
--!optimize 0
--!strict

type tests = { 
	suite: string, 
	name: string, 
	fn: () -> (),
}

type benchmarks = {
	suite: string,
	name: string,
	cases: { label: string, fn: () -> () }
}

local tests = {}
local benchmarks = {}

local function ASSERT_EQ<T>(actual: T, expected: T): ()
	if actual ~= expected then
		error(string.format("ASSERT_EQ failed: Expected: %s, Actual: %s", tostring(expected), tostring(actual)), 2)
	end
end

local function ASSERT_NE<T>(actual: T, expected: T): ()
	if actual == expected then
		error(string.format("ASSERT_NE failed: Expected %s to be different from %s", tostring(expected), tostring(actual)), 2)
	end
end

local function ASSERT_TRUE(condition: boolean): ()
	if not condition then
		error("ASSERT_TRUE failed: Condition is false", 2)
	end
end

local function ASSERT_FALSE(condition: boolean): ()
	if condition then
		error("ASSERT_FALSE failed: Condition is true", 2)
	end
end

local function ASSERT_LT(actual: number, expected: number): ()
	if actual >= expected then
		error(string.format("ASSERT_LT failed: Expected %s to be less than %s", tostring(actual), tostring(expected)), 2)
	end
end

local function ASSERT_LE(actual: number, expected: number): ()
	if actual > expected then
		error(string.format("ASSERT_LE failed: Expected %s to be less than or equal to %s", tostring(actual), tostring(expected)), 2)
	end
end

local function ASSERT_GT(actual: number, expected: number): ()
	if actual <= expected then
		error(string.format("ASSERT_GT failed: Expected %s to be greater than %s", tostring(actual), tostring(expected)), 2)
	end
end

local function ASSERT_GE(actual: number, expected: number): ()
	if actual < expected then
		error(string.format("ASSERT_GE failed: Expected %s to be greater than or equal to %s", tostring(actual), tostring(expected)), 2)
	end
end

local function ASSERT_NEAR(actual: number, expected: number, tolerance: number): ()
	if math.abs(actual - expected) > tolerance then
		error(string.format("ASSERT_NEAR failed: Expected %s to be within %s of %s", tostring(actual), tostring(tolerance), tostring(expected)), 2)
	end
end

local function TEST(test_suite: string, test_name: string): (callback: () -> string) -> ()
	return function(callback: () -> string): ()
		table.insert(tests, { suite = test_suite, name = test_name, fn = callback })
	end
end

local function COLOR_TEXT(colorCode: string, text: string): string
	return string.format("\27[%sm%s\27[0m", colorCode, text)
end

local function RUN_ALL_TEST(): ()
	local passed = 0
	local failed = 0

	print("========== Running Tests ==========")

	for _, t in tests do
		local success, err = pcall(t.fn)
		if success then
			print(COLOR_TEXT("32", string.format("[PASSED] %s.%s", t.suite, t.name)))
			passed += 1
		else
			print(COLOR_TEXT("31", string.format("[FAILED] %s.%s\t%s", t.suite, t.name, err)))
			failed += 1
		end
	end

	print("\n========== Test Summary ==========")
	print(COLOR_TEXT("32", string.format("Passed: %d", passed)))
	print(COLOR_TEXT("31", string.format("Failed: %d", failed)))
	print(string.format("Total Tests: %d", #tests))
end

local function BENCH(bench_suite: string, bench_name: string): { CASE: (label: string, fn: () -> ()) -> () }
	local suiteCases = {}

	local function CASE(label: string, fn: () -> ()): ()
		table.insert(suiteCases, { label = label, fn = fn })
	end

	table.insert(benchmarks, { suite = bench_suite, name = bench_name, cases = suiteCases })

	return { CASE = CASE }
end

local function RUN_ALL_BENCH(): ()
	print("\n========== Running Benchmarks ==========\n")

	for _, benchmark in benchmarks do
		print(string.format("Benchmark Suite: %s.%s", benchmark.suite, benchmark.name))

		for _, case in benchmark.cases do
			local caseLabel = case.label ~= "" and case.label or "Unnamed Case"

			local startMemory = gcinfo()
			local startTime = os.clock()

			case.fn()

			local endTime = os.clock()
			local endMemory = gcinfo()

			local duration = endTime - startTime
			local memoryUsed = endMemory - startMemory

			local timeStr: string, unit: string
			if duration >= 1 then
				timeStr = string.format("%.3f", duration)
				unit = "s"
			elseif duration >= 0.001 then
				timeStr = string.format("%.3f", duration * 1000)
				unit = "ms"
			else
				timeStr = string.format("%.3f", duration * 1000000)
				unit = "µs"
			end

			print(string.format(
				"Case '%s': %s %s | Memory: %.2f KB",
				caseLabel, timeStr, unit, memoryUsed
				))
		end
	end

	print("\n========== Benchmark Summary ==========\n")
end

return table.freeze({
	ASSERT_EQ = ASSERT_EQ,
	ASSERT_GE = ASSERT_GE,
	ASSERT_GT = ASSERT_GT,
	ASSERT_LE = ASSERT_LE,
	ASSERT_LT = ASSERT_LT,
	ASSERT_NE = ASSERT_NE,
	ASSERT_NEAR = ASSERT_NEAR,
	ASSERT_TRUE = ASSERT_TRUE,
	ASSERT_FALSE = ASSERT_FALSE,

	TEST = TEST,
	BENCH = BENCH,
	RUN_ALL_TEST = RUN_ALL_TEST,
	RUN_ALL_BENCH = RUN_ALL_BENCH
})
