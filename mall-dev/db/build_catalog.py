"""Download sourced product photos and build the clean local supermarket SQL seed."""

from concurrent.futures import ThreadPoolExecutor, as_completed
from io import BytesIO
from pathlib import Path
import json

import requests
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "db"
IMAGES = ROOT / "img" / "product"
CATALOG = json.loads((DB / "catalog.json").read_text(encoding="utf-8"))

CATEGORIES = [
    (1, 0, "食品饮料", 1), (2, 0, "生鲜果蔬", 2),
    (3, 0, "家清日用", 3), (4, 0, "服饰鞋包", 4),
    (5, 0, "家具家纺", 5), (6, 0, "家用电器", 6),
    (7, 0, "数码电子", 7),
    (11, 1, "粮油乳品", 1), (12, 1, "零食饮品", 2),
    (21, 2, "水果蔬菜", 1), (22, 2, "肉蛋食品", 2),
    (31, 3, "纸品清洁", 1), (32, 3, "个护用品", 2),
    (41, 4, "上衣袜品", 1), (42, 4, "居家鞋履", 2),
    (51, 5, "家具收纳", 1), (52, 5, "床品家纺", 2),
    (61, 6, "厨房小电", 1), (62, 6, "大家电", 2),
    (71, 7, "数码配件", 1), (72, 7, "电脑外设", 2),
]

def quote(value):
    return "'" + str(value).replace("\\", "\\\\").replace("'", "''") + "'"

def fetch_photo(index, item):
    response = requests.get(item["photo"], timeout=35,
                            headers={"User-Agent": "Mozilla/5.0 (compatible; MallCatalog/1.0)"})
    response.raise_for_status()
    data = response.content
    if len(data) < 3000 or len(data) > 12_000_000:
        raise ValueError(f"Unexpected image size: {len(data)} bytes")
    with Image.open(BytesIO(data)) as picture:
        if picture.width < 250 or picture.height < 250:
            raise ValueError(f"Image too small: {picture.size}")
        suffix = {"JPEG": "jpg", "PNG": "png", "WEBP": "webp"}.get(picture.format)
        if not suffix:
            raise ValueError(f"Unsupported image format: {picture.format}")
    filename = f"product-{index:03d}.{suffix}"
    (IMAGES / filename).write_bytes(data)
    return index, filename

def main():
    IMAGES.mkdir(parents=True, exist_ok=True)
    if len({item["name"] for item in CATALOG}) != len(CATALOG):
        raise ValueError("Duplicate product names")
    names = {}
    errors = []
    with ThreadPoolExecutor(max_workers=7) as pool:
        futures = {pool.submit(fetch_photo, i, item): i for i, item in enumerate(CATALOG, 1)}
        for future in as_completed(futures):
            try:
                index, filename = future.result()
                names[index] = filename
                print(f"photo {index:02d}: {filename}")
            except Exception as exc:
                errors.append(f"photo {futures[future]:02d}: {exc}")
    if errors:
        raise RuntimeError("Photo downloads failed:\n" + "\n".join(errors))

    schema = (DB / "schema.sql").read_text(encoding="utf-8")
    import re
    tables = re.findall(r"CREATE TABLE `([^`]+)`", schema)
    if len(tables) != 10:
        raise ValueError("Expected 10 database tables")
    lines = [
        "-- Local demonstration database. Importing this file replaces existing mall tables.",
        "-- Brand/model/specification sourced from db/catalog.json. Prices and stock are demo values.",
        "CREATE DATABASE IF NOT EXISTS mall CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;",
        "USE mall;", "SET NAMES utf8mb4;", "SET FOREIGN_KEY_CHECKS=0;",
    ]
    lines += [f"DROP TABLE IF EXISTS `{name}`;" for name in reversed(tables)]
    lines.append(schema)
    for cid, parent, label, sort in CATEGORIES:
        lines.append(f"INSERT INTO pms_category (id,parent_id,name,sort,icon,is_deleted) VALUES ({cid},{parent},{quote(label)},{sort},'',0);")
    for index, item in enumerate(CATALOG, 1):
        lines.append("INSERT INTO pms_product (id,name,price,stock,detail,category_id,status,version,is_deleted) VALUES "
                     f"({index},{quote(item['name'])},{item['price']:.2f},{item['stock']},{quote(item['detail'])},{item['category_id']},1,1,0);")
        lines.append("INSERT INTO pms_product_img (id,product_id,url,sort,is_deleted) VALUES "
                     f"({index},{index},{quote(names[index])},0,0);")
    demo_hash = "$2a$10$lLLBS06gXc.vGYeQto8SEOMciEOY16lfu8o41PMWD12RUpWFpBqwe"
    lines.append("INSERT INTO sys_user (id,code,name,pwd,role,status,is_deleted) VALUES "
                 f"(1,'admin','管理员',{quote(demo_hash)},1,1,0),(2,'user','演示用户',{quote(demo_hash)},0,1,0);")
    lines.append("SET FOREIGN_KEY_CHECKS=1;")
    (DB / "mall.sql").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Built {len(CATEGORIES)} categories, {len(CATALOG)} sourced products")

if __name__ == "__main__":
    main()
