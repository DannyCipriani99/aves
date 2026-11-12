package deckers.thibault.aves.model.provider

import android.content.Context
import android.net.Uri
import android.util.Log
import android.webkit.MimeTypeMap
import deckers.thibault.aves.model.FieldMap
import deckers.thibault.aves.storage.StorageUtils.ensureTrailingSeparator
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.utils.MimeTypes
import java.io.File

// Scans directories directly on the file system, bypassing the Media Store,
// so that items in hidden directories or directories with a `.nomedia` file can be listed.
object FileSystemScanner {
    private val LOG_TAG = LogUtils.createTag<FileSystemScanner>()

    fun scan(
        context: Context,
        includedPaths: List<String>,
        excludedPaths: List<String>,
        knownPaths: Set<String>,
        scanHidden: Boolean,
        handleNewEntry: NewEntryHandler,
    ) {
        val excludedPrefixes = excludedPaths.map { ensureTrailingSeparator(it) }
        val provider = FileImageProvider()
        val visited = HashSet<String>()

        fun isExcluded(file: File) = excludedPrefixes.any { (file.path + File.separator).startsWith(it) }

        fun handleFile(file: File) {
            val path = file.path
            if (knownPaths.contains(path) || isExcluded(file)) return
            val extension = file.extension.lowercase()
            val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: return
            if (!MimeTypes.isImage(mimeType) && !MimeTypes.isVideo(mimeType)) return

            provider.fetchSingle(
                context = context,
                sourceMimeType = mimeType,
                uri = Uri.fromFile(file),
                allowUnsized = false,
                callback = object : ImageProvider.ImageOpCallback {
                    override fun onSuccess(fields: FieldMap) = handleNewEntry(fields)
                    override fun onFailure(throwable: Throwable) {
                        Log.w(LOG_TAG, "failed to scan file at path=$path", throwable)
                    }
                },
            )
        }

        fun walk(dir: File) {
            val canonical = try {
                dir.canonicalPath
            } catch (e: Exception) {
                return
            }
            // guard against symlink loops
            if (!visited.add(canonical) || isExcluded(dir)) return
            val children = dir.listFiles() ?: return
            for (child in children) {
                if (child.isDirectory) {
                    if (!scanHidden && child.name.startsWith(".")) continue
                    walk(child)
                } else if (child.isFile) {
                    // dot-prefixed files are hidden too
                    if (!scanHidden && child.name.startsWith(".")) continue
                    handleFile(child)
                }
            }
        }

        includedPaths.forEach { path ->
            val root = File(path)
            if (root.isDirectory) {
                walk(root)
            } else {
                Log.w(LOG_TAG, "included path=$path is not an accessible directory")
            }
        }
    }
}
