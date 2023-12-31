## <b>OSPI_NOR_AutoPolling_DTR Example Description</b>

How to use an OSPI NOR memory in Automatic polling mode.

This example describes how to write and read data in Automatic polling mode in an OSPI
NOR memory and compare the result.

At the beginning of the main program the HAL_Init() function is called to reset
all the peripherals, initialize the Flash interface and the systick.

The SystemClock_Config() function is used to configure the system clock for STM32H573AIIx Devices :
the CPU at 250 MHz.

- LED_GREEN is ON when the checked data is correct.
- LED_ORANGE is ON as soon as a comparison error occurs.
- LED_ORANGE toggles as soon as an error is returned by HAL API.

#### <b>Notes</b>

 1. Care must be taken when using HAL_Delay(), this function provides accurate delay (in milliseconds)
    based on variable incremented in SysTick ISR. This implies that if HAL_Delay() is called from
    a peripheral ISR process, then the SysTick interrupt must have higher priority (numerically lower)
    than the peripheral interrupt. Otherwise the caller ISR process will be blocked.
    To change the SysTick interrupt priority you have to use HAL_NVIC_SetPriority() function.

 2. The application needs to ensure that the SysTick time base is always set to 1 millisecond
    to have correct HAL operation.

### <b>Keywords</b>

Memory, OCTOSPI, DLYB, Read, Write, auto polling, NOR, DTR Mode

### <b>Directory contents</b>

  - OCTOSPI/OSPI_NOR_AutoPolling_DTR/Inc/stm32h5xx_hal_conf.h     HAL configuration file
  - OCTOSPI/OSPI_NOR_AutoPolling_DTR/Inc/stm32h5xx_it.h           Interrupt handlers header file
  - OCTOSPI/OSPI_NOR_AutoPolling_DTR/Inc/main.h                   Header for main.c module
  - OCTOSPI/OSPI_NOR_AutoPolling_DTR/Src/stm32h5xx_it.c           Interrupt handlers
  - OCTOSPI/OSPI_NOR_AutoPolling_DTR/Src/main.c                   Main program
  - OCTOSPI/OSPI_NOR_AutoPolling_DTR/Src/stm32h5xx_hal_msp.c      HAL MSP module
  - OCTOSPI/OSPI_NOR_AutoPolling_DTR/Src/system_stm32h5xx.c       STM32H5xx system source file

### <b>Hardware and Software environment</b>

  - This example runs on STM32H573AIIx devices without security enabled (TZEN=0).

  - This template has been tested with STMicroelectronics STM32H573I-DK
    board and can be easily tailored to any other supported device
    and development board.

### <b>How to use it ?</b>

In order to make the program work, you must do the following:

 - Open your preferred toolchain
 - Rebuild all files and load your image into target memory
 - Run the example

