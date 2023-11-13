package lol.bruh19.azari.gallery

import android.util.Log
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

private fun wrapResult(result: Any?): List<Any?> {
    return listOf(result)
}

private fun wrapError(exception: Throwable): List<Any?> {
    if (exception is FlutterError) {
        return listOf(
            exception.code,
            exception.message,
            exception.details
        )
    } else {
        return listOf(
            exception.javaClass.simpleName,
            exception.toString(),
            "Cause: " + exception.cause + ", Stacktrace: " + Log.getStackTraceString(exception)
        )
    }
}

/**
 * Error class for passing custom error details to Flutter via a thrown PlatformException.
 * @property code The error code.
 * @property message The error message.
 * @property details The error details. Must be a datatype supported by the api codec.
 */
class FlutterError(
    val code: String,
    override val message: String? = null,
    val details: Any? = null
) : Throwable()

/** Generated class from Pigeon that represents data sent in messages. */
data class Directory(
    val thumbFileId: Long,
    val bucketId: String,
    val name: String,
    val relativeLoc: String,
    val volumeName: String,
    val lastModified: Long

) {
    companion object {
        @Suppress("UNCHECKED_CAST")
        fun fromList(list: List<Any?>): Directory {
            val thumbFileId = list[0].let { if (it is Int) it.toLong() else it as Long }
            val bucketId = list[1] as String
            val name = list[2] as String
            val relativeLoc = list[3] as String
            val volumeName = list[4] as String
            val lastModified = list[5].let { if (it is Int) it.toLong() else it as Long }
            return Directory(thumbFileId, bucketId, name, relativeLoc, volumeName, lastModified)
        }
    }

    fun toList(): List<Any?> {
        return listOf<Any?>(
            thumbFileId,
            bucketId,
            name,
            relativeLoc,
            volumeName,
            lastModified,
        )
    }
}

/** Generated class from Pigeon that represents data sent in messages. */
data class DirectoryFile(
    val id: Long,
    val bucketId: String,
    val name: String,
    val originalUri: String,
    val lastModified: Long,
    val height: Long,
    val width: Long,
    val size: Long,
    val isVideo: Boolean,
    val isGif: Boolean

) {
    companion object {
        @Suppress("UNCHECKED_CAST")
        fun fromList(list: List<Any?>): DirectoryFile {
            val id = list[0].let { if (it is Int) it.toLong() else it as Long }
            val bucketId = list[1] as String
            val name = list[2] as String
            val originalUri = list[3] as String
            val lastModified = list[4].let { if (it is Int) it.toLong() else it as Long }
            val height = list[5].let { if (it is Int) it.toLong() else it as Long }
            val width = list[6].let { if (it is Int) it.toLong() else it as Long }
            val size = list[7].let { if (it is Int) it.toLong() else it as Long }
            val isVideo = list[8] as Boolean
            val isGif = list[9] as Boolean
            return DirectoryFile(
                id,
                bucketId,
                name,
                originalUri,
                lastModified,
                height,
                width,
                size,
                isVideo,
                isGif
            )
        }
    }

    fun toList(): List<Any?> {
        return listOf<Any?>(
            id,
            bucketId,
            name,
            originalUri,
            lastModified,
            height,
            width,
            size,
            isVideo,
            isGif,
        )
    }
}

@Suppress("UNCHECKED_CAST")
private object GalleryApiCodec : StandardMessageCodec() {
    override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? {
        return when (type) {
            128.toByte() -> {
                return (readValue(buffer) as? List<Any?>)?.let {
                    Directory.fromList(it)
                }
            }

            129.toByte() -> {
                return (readValue(buffer) as? List<Any?>)?.let {
                    DirectoryFile.fromList(it)
                }
            }

            else -> super.readValueOfType(type, buffer)
        }
    }

    override fun writeValue(stream: ByteArrayOutputStream, value: Any?) {
        when (value) {
            is Directory -> {
                stream.write(128)
                writeValue(stream, value.toList())
            }

            is DirectoryFile -> {
                stream.write(129)
                writeValue(stream, value.toList())
            }

            else -> super.writeValue(stream, value)
        }
    }
}

/** Generated class from Pigeon that represents Flutter messages that can be called from Kotlin. */
@Suppress("UNCHECKED_CAST")
class GalleryApi(private val binaryMessenger: BinaryMessenger) {
    companion object {
        /** The codec used by GalleryApi. */
        val codec: MessageCodec<Any?> by lazy {
            GalleryApiCodec
        }
    }

    fun updateDirectories(
        dArg: List<Directory>,
        inRefreshArg: Boolean,
        emptyArg: Boolean,
        callback: (Result<Unit>) -> Unit
    ) {
        val channel = BasicMessageChannel<Any?>(
            binaryMessenger,
            "lol.bruh19.azari.gallery.api.updateDirectories",
            codec
        )
        channel.send(listOf(dArg, inRefreshArg, emptyArg)) {
            if (it is List<*>) {
                if (it.size > 1) {
                    callback(
                        Result.failure(
                            FlutterError(
                                it[0] as String,
                                it[1] as String,
                                it[2] as String?
                            )
                        )
                    );
                } else {
                    callback(Result.success(Unit));
                }
            } else {
                callback(
                    Result.failure(
                        FlutterError(
                            "channel-error",
                            "Unable to establish connection on channel.",
                            ""
                        )
                    )
                );
            }
        }
    }

    fun updatePictures(
        fArg: List<DirectoryFile?>,
        bucketIdArg: String,
        startTimeArg: Long,
        inRefreshArg: Boolean,
        emptyArg: Boolean,
        callback: (Result<Unit>) -> Unit
    ) {
        val channel = BasicMessageChannel<Any?>(
            binaryMessenger,
            "lol.bruh19.azari.gallery.api.updateFiles",
            codec
        )
        channel.send(listOf(fArg, bucketIdArg, startTimeArg, inRefreshArg, emptyArg)) {
            if (it is List<*>) {
                if (it.size > 1) {
                    callback(
                        Result.failure(
                            FlutterError(
                                it[0] as String,
                                it[1] as String,
                                it[2] as String?
                            )
                        )
                    );
                } else {
                    callback(Result.success(Unit));
                }
            } else {
                callback(
                    Result.failure(
                        FlutterError(
                            "channel-error",
                            "Unable to establish connection on channel.",
                            ""
                        )
                    )
                );
            }
        }
    }

    fun notify(secondary: Boolean, callback: (Result<Unit>) -> Unit) {
        val c = binaryMessenger.send(
            "lol.bruh19.azari.gallery.api.notify",
            ByteBuffer.allocate(1).put((if (secondary) 1.toUByte() else 0.toUByte()).toByte())
        )
//        val channel = BasicMessageChannel<Any?>(
//            binaryMessenger,
//            "lol.bruh19.azari.gallery.api.notify",
//            codec
//        )
//        channel.send(listOf(if (secondary) 1.toUByte() else 0.toUByte())) {
//            if (it is List<*>) {
//                if (it.size > 1) {
//                    callback(
//                        Result.failure(
//                            FlutterError(
//                                it[0] as String,
//                                it[1] as String,
//                                it[2] as String?
//                            )
//                        )
//                    );
//                } else {
//                    callback(Result.success(Unit));
//                }
//            } else {
//                callback(
//                    Result.failure(
//                        FlutterError(
//                            "channel-error",
//                            "Unable to establish connection on channel.",
//                            ""
//                        )
//                    )
//                );
//            }
//        }
    }
}