# db2-prototypes

Throw away repo containing scripts and benchmarks of data import and querying from VIMC 2.0 database. For testing we will import data for 2022110gavi-3 touchstone for YF with 3 countries AGO, BEN and BFA.

How can we expect this to scale with more touchstones, more diseases and more countries?

## Imports

* 2022-03-15_add_tables - creates `metadata` and `stochastic_1` tables with sql query to set structure used by following imports
* 2022-03-14_central_import - contains script to pull centrals from montagu API and then a dettl import to add to the database
* 2022-03-15_stochastic_import - contains db import to upload stochastics from raw files into database. This transforms to a common pattern but does no aggregation

