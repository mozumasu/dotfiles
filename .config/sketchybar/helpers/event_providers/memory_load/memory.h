#include <mach/mach.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/sysctl.h> // sysctlを使うために必要

struct memory {
  mach_port_t host;
  vm_size_t page_size;
  uint64_t total_memory;
  double free_memory;
  double used_memory;
  double wired_memory;
  double page_purgeable_memory;
  double page_speculative_memory;
  double active_memory;
  double inactive_memory;
  double compressed_memory;
  double anonymous_memory;
  double compressor_memory;
  double used_percentage;
};

// vm_statコマンドからページ数を取得する関数
uint64_t get_pages_from_vm_stat(const char *label) {
    FILE *fp;
    char line[256];
    uint64_t pages = 0;

    // vm_statコマンドを実行
    fp = popen("vm_stat", "r");
    if (fp == NULL) {
        printf("Error: Failed to run vm_stat command.\n");
        return 0;
    }

    // 出力を1行ずつ読み込む
    while (fgets(line, sizeof(line), fp) != NULL) {
        // ラベルが一致する行を探す
        if (strstr(line, label) != NULL) {
            // "Pages free: 12345."の形式から数値を抽出
            char *token = strtok(line, ":");
            token = strtok(NULL, ".");
            if (token != NULL) {
                pages = strtoull(token, NULL, 10);
            }
            break;
        }
    }

    // popenを閉じる
    pclose(fp);

    return pages;
}

static inline void memory_init(struct memory *memory) {
  memory->host = mach_host_self();
  host_page_size(memory->host, &memory->page_size);
}

static inline void memory_update(struct memory *memory) {
  // システムの物理メモリ量を取得
  int mib[2] = {CTL_HW, HW_MEMSIZE};
  uint64_t physical_memory;
  size_t length = sizeof(physical_memory);
  if (sysctl(mib, 2, &physical_memory, &length, NULL, 0) != 0) {
    printf("Error: Could not read total physical memory.\n");
    return;
  }

  // vm_statから各ページ数を取得
  uint64_t free_pages = get_pages_from_vm_stat("Pages free");
  uint64_t compressor_pages = get_pages_from_vm_stat("Pages occupied by compressor");
  uint64_t anonymous_pages = get_pages_from_vm_stat("Anonymous pages");
  uint64_t wired_pages = get_pages_from_vm_stat("Pages wired down");
  uint64_t page_purgeable_memory = get_pages_from_vm_stat("Pages purgeable");
  uint64_t page_speculative_memory = get_pages_from_vm_stat("Pages speculative");
  uint64_t active_pages = get_pages_from_vm_stat("Pages active");
  uint64_t inactive_pages = get_pages_from_vm_stat("Pages inactive");

  // ページサイズとGB変換係数を設定
  double page_size = 16384.0; // ページサイズは16384バイト
  double gb_conversion = 1024.0 * 1024.0 * 1024.0;

  // メモリ情報をGB単位で計算
  memory->free_memory = (double)(free_pages * page_size) / gb_conversion;
  memory->compressor_memory = (double)(compressor_pages * page_size) / gb_conversion;
  memory->anonymous_memory = (double)(anonymous_pages * page_size) / gb_conversion;
  memory->wired_memory = (double)(wired_pages * page_size) / gb_conversion;
  memory->page_purgeable_memory = (double)(page_purgeable_memory * page_size) / gb_conversion;
  memory->page_speculative_memory = (double)(page_speculative_memory * page_size) / gb_conversion;
  memory->active_memory = (double)(active_pages * page_size) / gb_conversion;
  memory->inactive_memory = (double)(inactive_pages * page_size) / gb_conversion;

  // 使用メモリの計算
  memory->used_memory = memory->anonymous_memory + memory->wired_memory +
                        memory->compressor_memory + memory->page_purgeable_memory+ memory->page_speculative_memory;

  memory->total_memory = (double)physical_memory / gb_conversion; // システムの物理メモリ量をGB単位で使用

  // メモリ使用量のパーセンテージを計算
  memory->used_percentage =
      (memory->used_memory / memory->total_memory) * 100.0;
}
