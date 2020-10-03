# GUI编程

## 1. 简介

- Swing  
- AWT

## 2. AWT

### 2.1 AWT介绍

1. 包含了很多类和接口！ GUI：

2. 元素：窗口，按钮，文本框

3. java.awt

   ```java
   public class TestFrame {
       public static void main(String[] args) {
           //Frame
           Frame frame = new Frame("这是我的第一个Java图形化窗口");
           //需要可见
           frame.setVisible(true);
           //设置大小
           frame.setSize(500,500);
           //设置颜色
           frame.setBackground(new Color(246, 4, 125));
           //设置大小不可变
           frame.setResizable(false);
           //设置初始化位置
           frame.setLocation(200,200);
       }
   }
   ```

   ```java
   //窗口Frame
   public class Multiple {
       public static void main(String[] args) {
           MyFrame myFrame1 = new MyFrame(100,100,200,200);
           MyFrame myFrame2 = new MyFrame(100,300,200,200);
           MyFrame myFrame3 = new MyFrame(300,100,200,200);
           MyFrame myFrame4 = new MyFrame(300,300,200,200);
       }
   }
   class  MyFrame extends Frame {
       static int id = 1;
       public MyFrame(int x, int y, int width, int height) {
           super("窗口编号为：" + (++id));
           setBounds(x, y, width, height);
           setVisible(true);
           setResizable(false);
           setBackground(Color.BLACK);
       }
   }
   ```

   ```java
   //面板
   public class MyPanel {
       public static void main(String[] args) {
           Frame frame = new Frame();
           //panel 一个空间，但不能单独存在
           //面板
           Panel panel = new Panel();
           //设备布局
           frame.setLayout(null);
           //frame坐标
           frame.setBounds(300, 300, 500, 500);
           frame.setBackground(new Color(2, 3, 5));
           //Panel坐标，相对于frame
           panel.setBounds(50, 50, 400, 400);
           panel.setBackground(new Color(34, 200, 5));
           frame.add(panel);
           frame.setVisible(true);
           //监听事件，监听窗口
           frame.addWindowListener(new WindowAdapter() {
               //关闭的时候做的事情
               @Override
               public void windowClosing(WindowEvent e) {
                   System.exit(0);
               }
           });
       }
   }
   ```

   



