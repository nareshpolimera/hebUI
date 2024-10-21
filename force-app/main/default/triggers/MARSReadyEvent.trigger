trigger MARSReadyEvent on MARS_Ready_Event__e (after insert) {
     if(!KillSwitchUtils.shouldTriggersRun()) {
        return;
    }
    MARSPlatformEventService.consume(Trigger.new);
}