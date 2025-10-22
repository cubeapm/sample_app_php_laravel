<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Elastic\Apm\ElasticApm;

class SampleJob implements ShouldQueue
{
    use Queueable;

    /**
     * Create a new job instance.
     */
    public function __construct()
    {
        //
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        // Elastic APM does not automatically start transaction for
        // background jobs, so we need to do it.
        $transaction = ElasticApm::beginCurrentTransaction(
            'SampleJob', // transaction name
            'job' // transaction type
        );

        try {
            // Actual job logic here...
            echo "EXECUTED JOB";
        } catch (\Throwable $e) {
            // record the exception
            $transaction->createErrorFromThrowable($e);
            throw $e; // re-throw to let Laravel handle the failure
        } finally {
            $transaction->end();
        }
    }
}
