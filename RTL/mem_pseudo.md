START

LOOP forever

    Decode memory address

    IF custom instruction THEN
        Execute security/AES operation

    ELSE IF address belongs to AES MMIO THEN
        Access AES accelerator

    ELSE IF address belongs to Sensor SPI MMIO THEN
        Access SPI sensor interface

    ELSE IF address belongs to UART MMIO THEN
        Access UART peripheral

    ELSE IF address belongs to Interrupt Controller THEN
        Access interrupt registers

    ELSE IF address belongs to DMA MMIO THEN
        Access DMA controller

    ELSE IF address belongs to Power MMIO THEN
        Access power-management block

    ELSE
        Access normal RAM
    ENDIF

    IF read operation THEN
        Return requested data
    ENDIF

    IF write operation THEN
        Store incoming data
    ENDIF

    Monitor AES, UART, DMA, and Sensor interrupts

    Update sleep and activity status

END LOOP
