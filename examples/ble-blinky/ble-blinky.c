#include <nrf.h>
#include <nrf_sdm.h>
#include <nrf_nvic.h>
#include <ble.h>
#include <string.h>

// LED GPIOs on some chinese shield
#define BLINKY_PIN      30
#define CONECTED_PIN    31

extern volatile uint32_t __data_start__;
nrf_nvic_state_t nrf_nvic_state;

static const nrf_clock_lf_cfg_t sdClockConfig =
{
    .source       = NRF_CLOCK_LF_SRC_XTAL,
    .rc_ctiv      = 0,
    .rc_temp_ctiv = 0,
    .accuracy     = NRF_CLOCK_LF_ACCURACY_50_PPM
};

uint8_t advData[] = {
    2, BLE_GAP_AD_TYPE_FLAGS, (BLE_GAP_ADV_FLAG_LE_GENERAL_DISC_MODE |  BLE_GAP_ADV_FLAG_BR_EDR_NOT_SUPPORTED),
    13, BLE_GAP_AD_TYPE_SHORT_LOCAL_NAME, 'n', 'R', 'F', '5', '2', '-', 'b', 'l', 'i', 'n', 'k', 'y'
};

ble_gap_adv_data_t sdAdvData = {
    {advData, sizeof(advData)},
    {NULL, 0}
};

static ble_gap_adv_params_t advertiseParams;
static uint8_t advertiseHandle = BLE_GAP_ADV_SET_HANDLE_NOT_SET;
static char name[] = "nRF52-blinky";

static uint8_t bleEvtBuffer[BLE_EVT_LEN_MAX(BLE_GATT_ATT_MTU_DEFAULT)];

ble_gatts_char_handles_t blinkyCharHandle;
static uint8_t blinkyCharValue = 0;

static void sdFaultHandler(uint32_t id, uint32_t pc, uint32_t info)
{
    for(;;);
}

static uint32_t gpioInit()
{
    NRF_GPIO->DIRSET = (1 << BLINKY_PIN) | (1 << CONECTED_PIN);
    NRF_GPIO->OUTCLR = (1 << BLINKY_PIN) | (1 << CONECTED_PIN);

    return 0;
}

static uint32_t sdInit(uint8_t tag)
{
    uint32_t result;
    uint32_t ramStart = (uint32_t)&__data_start__;

    ble_cfg_t ble_cfg;

    memset(&ble_cfg, 0, sizeof(ble_cfg));
    ble_cfg.conn_cfg.conn_cfg_tag                     = tag;
    ble_cfg.conn_cfg.params.gap_conn_cfg.conn_count   = BLE_GAP_CONN_COUNT_DEFAULT;
    ble_cfg.conn_cfg.params.gap_conn_cfg.event_length = BLE_GAP_EVENT_LENGTH_DEFAULT;

    result = sd_ble_cfg_set(BLE_CONN_CFG_GAP, &ble_cfg, ramStart);
    if (result != NRF_SUCCESS)
        return result;

    memset(&ble_cfg, 0, sizeof(ble_cfg));
    ble_cfg.gap_cfg.role_count_cfg.periph_role_count  = BLE_GAP_ROLE_COUNT_PERIPH_DEFAULT;

    result = sd_ble_cfg_set(BLE_GAP_CFG_ROLE_COUNT, &ble_cfg, ramStart);
    if (result != NRF_SUCCESS)
        return result;

    result = sd_ble_enable(&ramStart);
    if (result != NRF_SUCCESS)
        return result;

    return NRF_SUCCESS;
}

static uint32_t advertizeInit(void)
{
    memset(&advertiseParams, 0, sizeof(advertiseParams));
    advertiseParams.properties.type = BLE_GAP_ADV_TYPE_CONNECTABLE_SCANNABLE_UNDIRECTED;
    advertiseParams.p_peer_addr     = NULL;
    advertiseParams.filter_policy   = BLE_GAP_ADV_FP_ANY;
    advertiseParams.interval        = 100;
    advertiseParams.duration        = 0;

    ble_gap_conn_sec_mode_t nameSecurity = {1, 1};
    sd_ble_gap_device_name_set(&nameSecurity, (uint8_t*)name, sizeof(name));
    return sd_ble_gap_adv_set_configure(&advertiseHandle, &sdAdvData, &advertiseParams);
}

static uint32_t advertizeStart()
{
    return sd_ble_gap_adv_start(advertiseHandle, 0xDE);
}

static uint32_t advertizeStop()
{
    return sd_ble_gap_adv_stop(advertiseHandle);
}


static uint32_t gattInit()
{
    int status = 0;

    uint8_t vendorUUIDIdx;

    ble_uuid128_t vendorUUID = {{0x46, 0xb7, 0xc2, 0x11, 0xe0, 0x1c, 0x48, 0xdb, 0x91, 0xd6, 0xbb, 0x21, 0x00, 0x00, 0xe8, 0x61}};
    status = sd_ble_uuid_vs_add(&vendorUUID, &vendorUUIDIdx);
    if (status)
        return status;

    ble_uuid_t serviceUUID = {0x0001, vendorUUIDIdx};
    uint16_t gattServiceHandle;

    status = sd_ble_gatts_service_add(BLE_GATTS_SRVC_TYPE_PRIMARY, &serviceUUID, &gattServiceHandle);
    if (status)
        return status;

    ble_gatts_char_md_t blinkyCharMeta;
    memset(&blinkyCharMeta, 0, sizeof(blinkyCharMeta));
    blinkyCharMeta.char_props.read = 1;
    blinkyCharMeta.char_props.write_wo_resp = 1;

    ble_gatts_attr_md_t blinkyCharAttributeMeta;
    ble_gap_conn_sec_mode_t secOpen = {1, 1};
    blinkyCharAttributeMeta.vlen = 0;
    blinkyCharAttributeMeta.vloc = BLE_GATTS_VLOC_USER;
    blinkyCharAttributeMeta.read_perm = secOpen;
    blinkyCharAttributeMeta.write_perm = secOpen;
    blinkyCharAttributeMeta.rd_auth = 0;
    blinkyCharAttributeMeta.wr_auth = 0;

    ble_uuid_t blinkyCharUUID = {0x0002, vendorUUIDIdx};
    ble_gatts_attr_t blinkyCharAttribute;

    blinkyCharAttribute.p_uuid = &blinkyCharUUID;
    blinkyCharAttribute.p_attr_md = &blinkyCharAttributeMeta;
    blinkyCharAttribute.init_len = 1;
    blinkyCharAttribute.init_offs = 0;
    blinkyCharAttribute.max_len = 1;
    blinkyCharAttribute.p_value = &blinkyCharValue;

    ble_gatts_char_handles_t gattCharHandle;

    status = sd_ble_gatts_characteristic_add(gattServiceHandle, &blinkyCharMeta, &blinkyCharAttribute, &gattCharHandle);
    if (status)
        return status;

    return NRF_SUCCESS;
}

void SD_EVT_IRQHandler(void)
{
    uint16_t len;
    while (sd_ble_evt_get(bleEvtBuffer, &len) == NRF_SUCCESS)
    {
        ble_evt_t *evt = (ble_evt_t*)bleEvtBuffer;
        if (evt->header.evt_id == BLE_GAP_EVT_CONNECTED)
        {
            advertizeStop();
            NRF_GPIO->OUTSET = (1 << CONECTED_PIN);
        }
        else if ((evt->header.evt_id == BLE_GAP_EVT_DISCONNECTED) ||
                 evt->header.evt_id == BLE_GAP_EVT_TIMEOUT)
        {
            advertizeStart();
            NRF_GPIO->OUTCLR = (1 << CONECTED_PIN);
        }
        else if (evt->header.evt_id == BLE_GATTS_EVT_WRITE)
        {
            if (blinkyCharValue)
                NRF_GPIO->OUTSET = (1 << BLINKY_PIN);
            else
                NRF_GPIO->OUTCLR = (1 << BLINKY_PIN);

        }
    }
}

int main()
{
    uint32_t result = sd_softdevice_enable(&sdClockConfig, sdFaultHandler);
    if (result)
        return result;

    gpioInit();

    sd_nvic_EnableIRQ((IRQn_Type)SD_EVT_IRQn);

    volatile uint32_t status;

    status = sdInit(0xDE);
    status = advertizeInit();
    status = gattInit();
    status = advertizeStart();

    for (;;);
    return 0;
}
