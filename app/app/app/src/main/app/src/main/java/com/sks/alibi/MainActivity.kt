package com.sks.alibi

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.sks.alibi.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.textView.text = "Hello SKS Alibi 👋"
    }
}
