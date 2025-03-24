<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ApiController;

// Route::get('/user', function (Request $request) {
//     return $request->user();
// })->middleware('auth:sanctum');

Route::get('/', [ApiController::class, 'index']);
Route::get('/param/{param}', [ApiController::class, 'param']);
Route::get('/exception', [ApiController::class, 'exception']);
Route::get('/api/{status}', [ApiController::class, 'api']);
Route::get('/status/{status}', [ApiController::class, 'status']);
Route::get('/job', [ApiController::class, 'job']);
Route::get('/redis', [ApiController::class, 'redis']);
Route::get('/mysql', [ApiController::class, 'mysql']);

