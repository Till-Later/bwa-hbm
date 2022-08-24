#include <stdio.h>

#include "accelerator_adapter.h"

#include "action_aligner.h"
#include "accelerator_performance_counters.h"

int main_mem(int argc, char *argv[]);

int main(int argc, char *argv[])
{        
    accelerator_performance_counters_init();

    accelerator_init(&Accelerator);

    main_mem(argc, argv);

    accelerator_destroy(&Accelerator);
    accelerator_performance_counters_write_results();

    return 0;
}