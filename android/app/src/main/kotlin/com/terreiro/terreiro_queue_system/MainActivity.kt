package com.terreiro.terreiro_queue_system

import android.app.ActivityManager
import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Ativa o modo kiosk (Lock Task) automaticamente ao iniciar
        // Nota: para funcionar sem Device Owner, o screen pinning precisa estar habilitado
        // ou o app precisa estar na lista de pinned apps
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val lockTaskModeState = activityManager.lockTaskModeState
            // Só inicia lockTask se ainda não estiver bloqueado
            if (lockTaskModeState == ActivityManager.LOCK_TASK_MODE_NONE) {
                // Comentado temporariamente para debugar o crash de impressão
                // startLockTask()
                android.util.Log.d("MainActivity", "LockTask ignorado para depuração")
            }
        } catch (e: SecurityException) {
            // Sem permissão de Device Owner — funciona normalmente sem kiosk forçado
            android.util.Log.w("MainActivity", "LockTask não disponível sem Device Owner: ${e.message}")
        }
    }
}
