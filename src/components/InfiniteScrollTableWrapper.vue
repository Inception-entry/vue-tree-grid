<template>
  <div>
    <div style="position: relative">
      <slot style="position: relative" ref="scrollWrap"
        >无限滚动组件中未添加任何内容</slot
      >
      <div
        class="to_top_btn"
        v-if="showTopBtn && showTopBtn_private"
        @click="scrollToTop"
      >
        <i class="el-icon-arrow-up"></i>
      </div>
      <div v-if="showLoadmoreBtn" class="load_more_btn">
        <el-button @click="getMoreData(false)">加载更多</el-button>
      </div>
      <slot name="hintBar">
        <div
          v-if="my_showHintBar && showBottomBar"
          ref="ref_hint_bar"
          class="hint_bar"
        ></div>
      </slot>
    </div>
  </div>
</template>

<script>
export default {
  /**
    * 无限滚动组件说明：
    * 本组件针对el-table，获取el-table中的table_wraper元素，并添加滚动监听事件
    1、必选 三个参数 scrollData(目前获取到的所有数据列表)、loadConfig(滚动加载的配置)、getMoreData(加载更多数据的方法)
    loadConfig示例：
    loadConfig: {
    loadingText: '玩命加载中',
        overText: '你已经碰到我的底线了（没有更多数据）',
        totalCount: 50, // 传totalCount 或者 isOver  ========== 重要 
        isOver: false, // 传isOver或者 totalCount  ========== 重要
        itemHeight: 40, // 每一行数据的最小高度，不传默认40
        distance: 40 // 触发滚动加载的距离 不传 则默认为20
    }
    2、必需侦听一个事件 setTableData ， ========== 重要
    该事件会传出一个数组arr，用户展示当前容器的滚动位置，可看见的数据。（使用arr去渲染dom来节约dom资源）
    3、对外暴露6个方法
    3.1 infiniteLoadStart 加载数据前调用 ========== 重要
    3.2 infiniteLoadEnd   加载数据结束时调用 ========== 重要
    3.3 scrollToTop		  滚动到顶部
    3.4 scrollToNextPage  滚动到下一页
    3.5 scrollToPrePage	  滚动到上一页
    3.6 updateTableSize	  传入的元素尺寸变化时调用
    使用$refs['这个组件的ref名称'].fn() 来调用，fn对应上述一个方法。
    
    注意点：
    isOver或totalCount 只用一种来控制是否结束
    */
  name: "InfiniteScrollTable",
  props: {
    scrollData: Array,
    loadConfig: Object,
    getMoreData: Function,
    scrollWraperType: {
      type: String,
      default: "table" // 滚动的容器， table: el-table容器，normal：常规容器
    },
    loadImmediate: {
      // 如果当前数据小于可视数据，立刻加载更多
      type: Boolean,
      default: true
    },
    showTopBtn: {
      type: Boolean,
      default: true
    },
    showBottomBar: {
      type: Boolean,
      default: true
    }
  },
  data() {
    return {
      showLoadmoreBtn: false,
      start: 0,
      canLoadMore: true,
      loadStatus: "none", // loading:加载中， over:没有更多数据， none：未加载
      first: true,
      slotDom: null,
      selectWrap: null, // 展示数据的固定窗格的容器
      tableDom: null, // element table中表格元素，里面再分colgroup和tbody
      tablebodyDom: null, // 每一行数据直接的父容器
      currTableRowList: [], // 存储展示的数据的数组
      scrollConfig: {
        distanceSign: 20,
        visibleCount: 20,
        startOffset: 0,
        itemHeight: 0,
        listHeight: 0,
        virtualDom: null,
        wrapperHeight: 0 // 记录容器的高度，和来比较当前是否可以需要加载更多
      },
      loadFnCount: 0,
      $currCount: 0,
      my_showHintBar: false,
      showHintTimer: null,
      beforeScrollDistance: 0,
      defaultSlot: null,
      DURATION: 2000,
      PADDING_BOTTOM: 0,
      showTopBtn_private: false,
      SHOW_TOP_BTN_DISTANCE: 200,
      DEFAULT_ITEMHEIGHT: 10
    };
  },
  watch: {
    scrollData: {
      immediate: false,
      deep: false,
      handler: function(arr) {
        const end = this.start + this.scrollConfig.visibleCount;
        this.$currCount = arr.length;
        this.handleCurrCountChange(this.$currCount);
        this.setTableData(this.start, end);
      }
    }
  },
  mounted() {
    // 检查必要传参
    if (!this.scrollData || !(this.scrollData instanceof Array)) {
      this.logErr(
        "infiniteScrollPlus 组件中必传 scrollData参数(实际数据列表，为数组)"
      );
      return this.$message.warning(
        "infiniteScrollPlus 组件中必传 scrollData参数(实际数据列表，为数组)"
      );
    }
    if (!this.loadConfig || typeof this.loadConfig !== "object") {
      this.logErr(
        "infiniteScrollPlus 组件中必传 loadConfig 参数(配置参数对象)"
      );
      return this.$message.warning(
        "infiniteScrollPlus 组件中必传 loadConfig 参数(配置参数对象)"
      );
    }
    if (
      this.loadConfig.totalCount === undefined &&
      this.loadConfig.isOver === undefined
    ) {
      this.logErr(
        "loadConfig 参数对象中必传 totalCount(数据库里数据总数) 或 isOver(是否结束)"
      );
      return this.$message.warning(
        "loadConfig 参数对象中必传 totalCount(数据库里数据总数) 或 isOver(是否结束)"
      );
    }
    if (!this.loadConfig.itemHeight) {
      this.logErr(
        "loadConfig 参数对象中未找到 itemHeight(每行高度)，为数字(不带px单位)；已取默认值40"
      );
      // return this.$message.warning("loadConfig 参数对象中必传 itemHeight(每行高度)，为数字(不带px单位)");
      this.loadConfig.itemHeight = 40;
    }
    if (!this.loadConfig.loadingText) {
      this.loadConfig.loadingText = "玩命加载中";
    }
    if (!this.loadConfig.overText) {
      this.loadConfig.overText = "你已经碰到我的底线了（没有更多数据）";
    }
    if (this.loadConfig.distance)
      this.scrollConfig.distanceSign = this.loadConfig.distance;
    // 设置基础值
    this.scrollConfig.visibleCount = this.$currCount || 30;
    this.defaultSlot = this.$slots.default[0];
    this.scrollConfig.itemHeight =
      this.loadConfig.itemHeight || this.DEFAULT_ITEMHEIGHT;
    if (!this.loadConfig.totalCount) this.loadConfig.totalCount = Infinity;
    if (!this.defaultSlot) {
      this.logErr("infiniteScrollPlus组件中需要包含子组件,且为一个");
      return this.$message.warning(
        "infiniteScrollPlus组件中需要包含子组件，且为一个"
      );
    }
    if (this.$slots.default.length > 1) {
      this.logErr("infiniteScrollPlus组件中只能包含一个子组件");
      return this.$message.warning(
        "infiniteScrollPlus组件中只能包含一个子组件"
      );
    }
    this.slotDom = this.defaultSlot.componentInstance.$el;
    if (this.scrollWraperType == "table") {
      this.selectWrap = this.slotDom.querySelector(".el-table__body-wrapper");
      if (!this.selectWrap)
        return this.$message("slot组件中未找到el-table容器");
      this.tableDom = this.selectWrap.querySelector("table");
      this.tablebodyDom = this.selectWrap.querySelector("tbody");
      if (!this.tableDom) return this.$message("slot组件中未找到table容器");
    } else {
      this.selectWrap = document.createElement("div");
      this.selectWrap.appendChild(this.slotDom);
      this.tableDom = this.slotDom;
      this.tablebodyDom = this.slotDom; // normal 情况下，获取滚动的总列表
    }
    this.$nextTick(() => {
      this.initScrollDom();
      // 判断当前元素，如果小于可是元素，那么加载更多。
      this.immediateGetMore();
      this.selectWrap.style.height = this.scrollConfig.wrapperHeight + "px";
    });
  },
  updated() {
    if (this.end - this.start > 0) {
      this.currTableRowList = [...this.tablebodyDom.children];
      this.calcRowHeight();
    }
  },
  methods: {
    // 更新每一行的高度数据
    calcRowHeight() {
      let showCount = this.end - this.start;
      for (let i = 0; i < showCount; i++) {
        if (this.currTableRowList[i] && this.scrollData[this.start + i]) {
          this.scrollData[this.start + i]["__height__"] = this.currTableRowList[
            i
          ].offsetHeight;
        }
      }
      this.updateVirtualDom();
    },
    handleCurrCountChange(value) {
      this.updateVirtualDom();
      if (value == 0) {
        this.loadStatus = "none";
        this.loadFnCount = 0;
        this.selectWrap.scrollTo({
          top: 0
        });
        this.start = 0;
        setTimeout(() => {
          this.tableDom.style.transform = this.getTranformTop(0);
        }, 100);
      }
    },
    updateTableSize() {
      setTimeout(() => {
        this.initScrollDom();
        this.selectWrap.style.height = this.scrollConfig.wrapperHeight + "px";
        setTimeout(() => {
          this.tableScrollEvent(true);
        }, 100);
      }, 100);
    },
    immediateGetMore() {
      if (
        this.$currCount < this.scrollConfig.visibleCount &&
        this.loadImmediate &&
        this.loadFnCount < 10
      ) {
        this.getMoreData();
        this.loadFnCount++;
      }
    },
    // 滚动到顶部
    scrollToTop() {
      this.selectWrap.scrollTo({
        top: 0,
        behavior: "smooth"
      });
    },
    // 滚动到下一页
    scrollToNextPage() {
      const { startOffset, itemHeight, wrapperHeight } = this.scrollConfig;
      let scrollY = startOffset + (wrapperHeight - itemHeight / 2);
      this.selectWrap.scrollTo({
        top: scrollY,
        behavior: "smooth"
      });
    },
    // 滚动到上一页
    scrollToPrePage() {
      const { startOffset, itemHeight, wrapperHeight } = this.scrollConfig;
      let scrollY = startOffset - (wrapperHeight - itemHeight / 2);
      this.selectWrap.scrollTo({
        top: scrollY,
        behavior: "smooth"
      });
    },
    // 初始化滚动相关dom元素
    initScrollDom() {
      let { selectWrap, tableDom, slotDom } = this;
      let scrollConfig = this.scrollConfig;
      let itemHeight = this.loadConfig.itemHeight;
      if (typeof itemHeight == "string") {
        itemHeight = itemHeight.replace("px", "");
      }
      itemHeight = Number(itemHeight) || 36;
      if (!itemHeight) {
        return this.logErr("未正确获取到子元素高度");
      }
      if (this.scrollWraperType == "table") {
        const theadDom = slotDom.querySelector(".el-table__header-wrapper");
        if (!theadDom) return this.logErr("未获取到thead dom元素");
        if (slotDom.clientHeight <= 100) {
          let height = this.defaultSlot.componentInstance.height;
          if (height && typeof height == "string") {
            height = Number(height.replace(/px/g, ""));
            scrollConfig.wrapperHeight = height - theadDom.clientHeight;
          } else {
            scrollConfig.wrapperHeight = 100;
          }
        } else {
          console.log(slotDom.clientHeight);
          scrollConfig.wrapperHeight =
            slotDom.clientHeight - theadDom.clientHeight;
        }
      } else {
        scrollConfig.wrapperHeight = tableDom.clientHeight;
      }
      if (scrollConfig.wrapperHeight <= 100) scrollConfig.wrapperHeight = 100;
      this.scrollConfig.visibleCount = Math.ceil(
        (scrollConfig.wrapperHeight + 500) / itemHeight
      );
      scrollConfig.itemHeight = itemHeight;
      // 设置容器样式
      selectWrap.style["overflow-y"] = "auto";
      // selectWrap.style["overflow-x"] = "auto";
      tableDom.style.position = "absolute";
      tableDom.style.left = 0;
      tableDom.style.top = 0;
      tableDom.style.width = "auto";
      tableDom.style["padding-bottom"] = this.PADDING_BOTTOM + "px";
      // 添加虚拟容器
      if (!scrollConfig.virtualDom) {
        scrollConfig.virtualDom = document.createElement("div");
        let styleObj = {
          height: scrollConfig.listHeight + "px",
          width: "100%",
          position: "absolute",
          left: 0,
          top: 0,
          "z-index": -1
        };
        Object.assign(scrollConfig.virtualDom.style, styleObj);
        selectWrap.appendChild(scrollConfig.virtualDom);
      }
      this.$currCount = this.scrollData.length;
      this.updateVirtualDom();
      this.addScrollEvent(selectWrap, tableDom);
    },
    // 更新虚拟列表的高度
    updateVirtualDom() {
      let scrollConfig = this.scrollConfig;
      let totalHeight = 0;
      this.scrollData.forEach(item => {
        let oneHeight = item.__height__ || this.loadConfig.itemHeight;
        totalHeight += oneHeight;
      });
      scrollConfig.listHeight = totalHeight + this.PADDING_BOTTOM;
      if (scrollConfig.virtualDom) {
        scrollConfig.virtualDom.style.height = scrollConfig.listHeight + "px";
      }
    },
    // 添加滚动事件
    addScrollEvent(selectWrap) {
      selectWrap.addEventListener("scroll", () => {
        this.tableScrollEvent();
      });
    },
    // 获取table中可视区域的偏移量
    getTranformTop(offset) {
      return `translate3d(0, ${offset}px, 0)`;
    },
    // 滚动事件
    tableScrollEvent(forceFlag) {
      let { selectWrap, scrollConfig, tableDom } = this;
      let distance = this.beforeScrollDistance - selectWrap.scrollTop;
      if (!forceFlag && Math.abs(distance) < 5) return;
      const distanceSign = scrollConfig.distanceSign;
      const { scrollHeight, scrollTop, clientHeight } = selectWrap;
      // 超过一定距离 展示回到顶部按钮
      if (scrollTop > this.SHOW_TOP_BTN_DISTANCE) {
        this.showTopBtn_private = true;
      } else {
        this.showTopBtn_private = false;
      }
      this.beforeScrollDistance = scrollTop;
      const scrollDistance = scrollHeight - scrollTop - clientHeight;
      // 计算被卷去的高度 占多少个数据 以及最上面一个数据离顶部的距离
      let scrollRowHeight = 0;
      let start = 0;
      for (let i = 0; i < this.$currCount; i++) {
        let oneRowHeight =
          this.scrollData[i].__height__ || scrollConfig.itemHeight;
        scrollRowHeight += oneRowHeight;
        if (scrollRowHeight > scrollTop) {
          scrollConfig.startOffset = scrollRowHeight - oneRowHeight;
          start = i;
          break;
        }
      }
      tableDom.style.transform = this.getTranformTop(scrollConfig.startOffset);
      const end = start + scrollConfig.visibleCount;
      this.setTableData(start, end);
      // console.log('滚动：', start, scrollTop, this.loadStatus, this.scrollConfig);
      if (scrollDistance < distanceSign && this.canLoadMore && !forceFlag) {
        if (this.loadStatus == "over") {
          this.addLoadSign("over", 1000);
        } else {
          this.getMoreData();
        }
      }
    },
    // 更新子元素中的tableData
    setTableData(start, end) {
      this.start = start;
      this.end = end;
      this.$emit("setTableData", this.scrollData.slice(start, end), [
        start,
        end
      ]);
    },
    loadStart() {
      this.infiniteLoadStart();
    },
    // 滚动开始
    infiniteLoadStart() {
      if (this.loadStatus == "over") {
        this.addLoadSign("over");
        return;
      }
      if (!this.canLoadMore) return;
      this.canLoadMore = false;
      this.loadStatus = "loading";
      this.addLoadSign("loading");
    },
    loadEnd() {
      this.infiniteLoadEnd();
    },
    // 滚动结束
    infiniteLoadEnd() {
      setTimeout(() => {
        this.canLoadMore = true;
        let loadConfig = this.loadConfig;
        if (this.$currCount >= loadConfig.totalCount || loadConfig.isOver) {
          this.loadStatus = "over";
          this.addLoadSign("over");
          return;
        } else {
          this.loadStatus = "none";
        }
        this.addLoadSign("none");
        // console.log(
        //     "加载完成",
        //     this.scrollConfig.visibleCount,
        //     this.loadStatus,
        //     this.loadConfig.totalCount,
        //     this.$currCount
        // );
        // 如果为立刻加载，每次加载结束会在判断是否需要继续加载
        if (this.loadImmediate) this.immediateGetMore();
      }, 0);
    },
    // 添加加载的尾部标识
    addLoadSign(type, duration) {
      let loadConfig = this.loadConfig;
      if (loadConfig.noSign) return;
      if (!duration) duration = this.DURATION;
      this.my_showHintBar = true;
      clearTimeout(this.showHintTimer);
      setTimeout(() => {
        let loadSignEle = this.$refs.ref_hint_bar;
        if (!loadSignEle) return;
        let total =
          loadConfig.totalCount != Infinity ? "/" + loadConfig.totalCount : "";
        if (type == "loading") {
          this.showLoadmoreBtn = false;
          loadSignEle.innerHTML =
            loadConfig.loadingText +
            ` ${this.$currCount}${total} <i class="el-icon-loading"></i>`;
        } else if (type == "over") {
          this.showLoadmoreBtn = false;
          loadSignEle.innerHTML =
            loadConfig.overText + ` ${this.$currCount}${total}`;
        } else {
          if (
            this.$currCount < this.scrollConfig.visibleCount &&
            !this.loadImmediate
          ) {
            this.showLoadmoreBtn = true;
          } else {
            this.showLoadmoreBtn = false;
          }
          loadSignEle.innerHTML = `数据：${this.$currCount}${total}`;
        }
      }, 0);
      this.showHintTimer = setTimeout(() => {
        this.my_showHintBar = false;
      }, duration);
    },
    // 打印错误
    logErr(errText) {
      console.log(" ==== tableLoadmore error ==== " + errText);
    }
  }
};
</script>

<style lang="less" scoped>
.load_more_btn {
  position: absolute;
  width: 100%;
  text-align: center;
  bottom: 0;
  box-sizing: border-box;
  z-index: 999999;
}
/deep/ .el-table__body-wrapper::-webkit-scrollbar {
  width: 8px;
  height: 12px;
}
/* 滚动条轨道 */
/deep/ .el-table__body-wrapper::-webkit-scrollbar-track {
  border-radius: 3px;
  background-color: #eaeaea;
  margin: 3px 0;
}
/* 滚动条里的小方块 */
/deep/ .el-table__body-wrapper::-webkit-scrollbar-thumb {
  border-radius: 5px;
  background-color: #d2d2d2;
}
.hint_bar {
  height: 1.5rem;
  width: 100%;
  line-height: 1.5rem;
  font-size: 1rem;
  text-align: center;
  position: absolute;
  bottom: 0;
  left: 0;
  padding-top: 5px;
  background-color: #ffffff;
}
.to_top_btn {
  position: absolute;
  display: inline-block;
  width: 2.2857rem;
  height: 2.2857rem;
  right: 2rem;
  bottom: 2rem;
  background-color: #dcdcdc9c;
  border-radius: 50%;
  cursor: pointer;
  font-size: 1.2rem;
  line-height: 2.2857rem;
  text-align: center;
}
</style>
