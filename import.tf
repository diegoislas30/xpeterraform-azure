# Archivo para importación de recursos existentes en Azure
# Los recursos importados se agregarán automáticamente a main.tf

# Importar ruta existente rt2LANCloud46 en rt-er2poc-test
import {
  to = azurerm_route.rt2LANCloud46
  id = "/subscriptions/9442ead9-7f87-4f7a-b248-53e511abefd7/resourceGroups/rg-xpeseg-test/providers/Microsoft.Network/routeTables/rt-er2poc-test/routes/rt2LANCloud46"
}
