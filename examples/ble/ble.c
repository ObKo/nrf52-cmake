#include <nrf.h>
#include <nrf_sdm.h>
#include <nrf_nvic.h>
#include <ble.h>
#include <string.h>

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
    6, BLE_GAP_AD_TYPE_SHORT_LOCAL_NAME, 'N', 'R', 'F', '5', '2'
};

ble_gap_adv_data_t sdAdvData = {
    {advData, sizeof(advData)},
    {NULL, 0}
};

static ble_gap_adv_params_t advertiseParams;
static uint8_t              advertiseHandle = BLE_GAP_ADV_SET_HANDLE_NOT_SET;
static char NAME[] = "NRF52";

static void sdFaultHandler(uint32_t id, uint32_t pc, uint32_t info)
{
    for(;;);
}

void SD_EVT_IRQHandler(void)
{
    for(;;);
}

uint32_t sdConfigure(uint8_t tag)
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
    sd_ble_gap_device_name_set(&nameSecurity, (uint8_t*)NAME, 5);
    return sd_ble_gap_adv_set_configure(&advertiseHandle, &sdAdvData, &advertiseParams);
}

static uint32_t advertizeStart()
{
    return sd_ble_gap_adv_start(advertiseHandle, 0xDE);
}

int main()
{
    uint32_t result = sd_softdevice_enable(&sdClockConfig, sdFaultHandler);
    if (result)
        return result;

    sd_nvic_EnableIRQ((IRQn_Type)SD_EVT_IRQn);

    volatile uint32_t status;

    status = sdConfigure(0xDE);
    status = advertizeInit();
    status = advertizeStart();

    for (;;);
    return 0;
}
