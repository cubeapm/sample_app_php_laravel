<?php

namespace App\Http\Controllers;

use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

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
}
