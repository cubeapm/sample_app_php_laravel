<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Redis;



Route::get('/', function () {
    return view('welcome');
});

Route::get('/exception', function () {
    throw new Exception('Sample exception');
});

Route::get('/api', function () {
    $response = Http::timeout(60)->get('http://localhost:8000/');
    if ($response->successful()) {
        return 'API called';
    }
    return response('Failed to call API', $response->status());
});

Route::get('/mysql', function () {
    try {
        $result = DB::select('SELECT NOW() as now');
        return response()->json(['status' => 'success', 'data' => $result]);
    } catch (\Exception $e) {
        return response()->json(['status' => 'error', 'message' => $e->getMessage()]);
    }
});

Route::get('/redis', function () {
    Redis::set('foo', 'bar');
    
    $value = Redis::get('foo');
    
    return response()->json(['message' => 'Redis called', 'value' => $value]);
});