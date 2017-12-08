# mdbci_provision_mark

This cookbook provides two recipes. One allows to put a mark on the machine that has been provisioned, the other removes this file. Placing the latter one in the beggining of the recipe list and the first one to the end of the list allows to detect whether chef run was successfull.
