class_name AdsConfig
extends RefCounted
## AdMob IDs + ad niyam EK jagah.
## Debug build (development / phone test) = Google ke TEST IDs. Release build = asli IDs.
## Apne phone par kabhi asli ad par click mat karo (AdMob account ban ho sakta hai).

# --- Asli (sirf release build mein)
const RELEASE_APP_ID := "ca-app-pub-9987799703505828~4755476455"
const RELEASE_INTERSTITIAL := "ca-app-pub-9987799703505828/4508064440"   # level_complete

# --- Google ke official TEST IDs (debug build)
const TEST_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const TEST_INTERSTITIAL := "ca-app-pub-3940256099942544/1033173712"

# --- Niyam
const FIRST_AD_LEVEL := 3            # level 1 aur 2 ke baad koi ad nahi
const MIN_GAP_SEC := 45.0            # do ads ke beech kam se kam itne second
const MAX_CONTENT_RATING := "PG"     # G / PG (code mein bhi, AdMob dashboard mein bhi)

# --- Test devices: in phones par release build mein bhi sirf TEST ads aate hain.
# ID logcat se milta hai (Ads SDK "setTestDeviceIds" / UMP "addTestDeviceHashedId" wali line).
const TEST_DEVICE_IDS: Array[String] = [
	"7D2A71DA27FCA926F22F631706426DD1",   # Rahul ka Samsung A71 (SM-A715F)
]

# --- Consent form test: debug build mein UMP ko "EEA user" maan kar form dikhao
# (sirf TEST_DEVICE_IDS wale phones par kaam karta hai).
const UMP_DEBUG_EEA := true


static func interstitial_id() -> String:
	return TEST_INTERSTITIAL if OS.is_debug_build() else RELEASE_INTERSTITIAL
