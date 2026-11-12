package deckers.thibault.aves.channel.streams.darttoplatform

import android.content.Context
import deckers.thibault.aves.channel.streams.BaseStreamHandler
import deckers.thibault.aves.model.provider.FileSystemScanner
import deckers.thibault.aves.model.provider.MediaStoreImageProvider
import deckers.thibault.aves.utils.LogUtils
import kotlinx.coroutines.launch

class MediaStoreStreamHandler(private val context: Context, arguments: Any?) : BaseStreamHandler() {
    // knownEntries: map of contentId -> dateModifiedMillis
    private var knownEntries: Map<Long?, Long?>? = null
    private var directory: String? = null
    private var excludedPaths: List<String> = emptyList()

    // file system scan of user-included directories (reaches hidden / `.nomedia` directories)
    private var includedPaths: List<String>? = null
    private var knownFilePaths: Set<String> = emptySet()
    private var scanHidden = false

    init {
        if (arguments is Map<*, *>) {
            knownEntries = (arguments["knownEntries"] as? Map<*, *>?)?.map { (it.key as Number?)?.toLong() to (it.value as Number?)?.toLong() }?.toMap()
            directory = arguments["directory"] as String?
            excludedPaths = (arguments["excludedPaths"] as? List<*>)?.filterIsInstance<String>() ?: emptyList()
            includedPaths = (arguments["includedPaths"] as? List<*>)?.filterIsInstance<String>()
            knownFilePaths = (arguments["knownFilePaths"] as? List<*>)?.filterIsInstance<String>()?.toSet() ?: emptySet()
            scanHidden = arguments["scanHidden"] as? Boolean ?: false
        }
    }

    override val logTag = LOG_TAG

    override fun onCall(args: Any?) {
        ioScope.launch { safe(if (includedPaths != null) ::fetchIncludedFiles else ::fetchAll) }
    }

    private fun fetchAll() {
        MediaStoreImageProvider().fetchAll(context, knownEntries ?: emptyMap(), directory, { success(it) }, excludedPaths)
        endOfStream()
    }

    private fun fetchIncludedFiles() {
        FileSystemScanner.scan(
            context = context,
            includedPaths = includedPaths ?: emptyList(),
            excludedPaths = excludedPaths,
            knownPaths = knownFilePaths,
            scanHidden = scanHidden,
        ) { success(it) }
        endOfStream()
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<MediaStoreStreamHandler>()
        const val CHANNEL = "deckers.thibault/aves/media_store_stream"
    }
}