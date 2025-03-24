<?php

namespace App\Http\Controllers;

use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use App\Jobs\SampleJob;

class ApiController extends Controller
{
    public function index(Request $request)
    {
        return response()->json(['message' => 'Hello!']);
    }

    public function param(Request $request, string $param)
    {
        return response()->json(['param' => $param]);
    }

    public function exception(Request $request)
    {
        throw new Exception("Sample exception");
    }

    public function api(Request $request, string $status)
    {
        $response = Http::get("http://localhost/api/status/{$status}");
        return response()->json(['message' => 'API called']);
    }

    public function status(Request $request, int $status)
    {
        return response()->json([
            'message' => 'Status response',
        ], $status);
    }

    public function job(Request $request)
    {
        // Dispatch the job immediately
        SampleJob::dispatch();

        // schedule it to run after a delay
        // SampleJob::dispatch()->delay(now()->addMinutes(5));

        return response()->json(['message' => 'Job scheduled!']);
    }

    public function redis(Request $request)
    {
        Cache::put('foo', 'bar', 600);
        return response()->json(['message' => 'Redis called']);
    }

    public function mysql()
    {
        $data = DB::select('SELECT * FROM user');
        return response()->json($data);
    }

}
