/// Where the app finds its illustrated designs (your public GitHub repo
/// kumar-procom-github/claude-repository, folder ahvanam-templates/).
///
/// The small design list is read straight from GitHub so new designs show up
/// within minutes of being pushed. The artwork itself comes through jsDelivr's
/// free CDN (fast in India). No API keys.
const templateCatalogUrl =
    'https://raw.githubusercontent.com/kumar-procom-github/claude-repository/main/ahvanam-templates/catalog.json';

/// Base for `art/…` and `thumbs/…` paths inside catalog.json.
const templateAssetBase = 'https://cdn.jsdelivr.net/gh/kumar-procom-github/claude-repository@main/ahvanam-templates/';

/// Background-music library for video invitations (same repo, folder
/// ahvanam-music/). Only original, royalty-free tracks go here.
const musicCatalogUrl =
    'https://raw.githubusercontent.com/kumar-procom-github/claude-repository/main/ahvanam-music/catalog.json';
const musicAssetBase = 'https://cdn.jsdelivr.net/gh/kumar-procom-github/claude-repository@main/ahvanam-music/';

/// Pictures of gods for the start of video invitations (same repo, folder
/// ahvanam-deities/, one file per god: ganesha.png, venkateswara.png …).
/// Only pictures you have the right to use go here. Missing ones fall back
/// to a drawn symbol (Om, namam, cross, crescent).
const deityAssetBase = 'https://cdn.jsdelivr.net/gh/kumar-procom-github/claude-repository@main/ahvanam-deities/';
