<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Custom Instrumentation Example based on Datadog docs
        if (extension_loaded('ddtrace')) {
            \DDTrace\trace_method('App\Http\Controllers\ApiController', 'param', function (\DDTrace\SpanData $span, array $args) {
                $span->name = 'custom.api.param';
                $span->resource = 'ApiController.param';
                if (isset($args[1])) {
                    $span->meta['custom.param_value'] = $args[1];
                }
            });
        }
    }
}
